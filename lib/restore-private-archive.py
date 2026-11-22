#!/usr/bin/env python3
"""Restore an authenticated runtime tar without replacing existing files.

The destination root and policy are trusted module arguments; archive names are
not trusted. No extract()/extractall(), links, special files, path traversal,
symlink ancestors or replacement of existing destinations are permitted. Logs
contain labels and counts, never file contents or archived member names.
"""

import argparse
import errno
import os
from pathlib import PurePosixPath
import pwd
import secrets
import stat
import sys
import tarfile

MAX_FILES = 4096
MAX_FILE_BYTES = 64 * 1024 * 1024
MAX_TOTAL_BYTES = 256 * 1024 * 1024


class RejectedArchive(ValueError):
    pass


def parts_for(name, *, empty=False):
    if not isinstance(name, str) or "\\" in name or "\0" in name:
        raise RejectedArchive("invalid archive path")
    path = PurePosixPath(name)
    if path.is_absolute() or ".." in path.parts or any(":" in p for p in path.parts):
        raise RejectedArchive("unsafe archive path")
    parts = tuple(p for p in path.parts if p != ".")
    if not parts and not empty:
        raise RejectedArchive("empty archive path")
    return parts


def selected_members(
    archive, *, prefix="", flat=False, allow_files=(), allow_suffixes=()
):
    prefix_parts = parts_for(prefix, empty=True)
    allowed = {parts_for(name) for name in allow_files}
    if any(
        not suffix.startswith(".") or "/" in suffix or "\\" in suffix
        for suffix in allow_suffixes
    ):
        raise RejectedArchive("invalid allowed suffix")
    chosen = []
    seen = set()
    total = 0
    for index, member in enumerate(archive, 1):
        if index > MAX_FILES:
            raise RejectedArchive("archive exceeds the member count limit")
        parts = parts_for(member.name, empty=member.isdir())
        if not (member.isdir() or member.isreg()):
            raise RejectedArchive("archive contains a link or special file")
        if member.issparse():
            raise RejectedArchive("sparse files are not accepted")
        if not parts:
            continue
        if prefix_parts:
            if parts == prefix_parts and member.isdir():
                continue
            if parts[: len(prefix_parts)] != prefix_parts:
                raise RejectedArchive("archive member is outside the required prefix")
            parts = parts[len(prefix_parts) :]
        if not parts:
            raise RejectedArchive("empty destination path")
        if flat and len(parts) != 1:
            raise RejectedArchive("archive must contain basenames only")
        if member.isdir():
            continue
        if allowed and parts not in allowed:
            raise RejectedArchive("archive contains an unexpected file")
        if allow_suffixes and not any(
            parts[-1].endswith(suffix) for suffix in allow_suffixes
        ):
            raise RejectedArchive("archive contains an unexpected file suffix")
        if parts in seen:
            raise RejectedArchive("duplicate destination path")
        seen.add(parts)
        if member.size < 0 or member.size > MAX_FILE_BYTES:
            raise RejectedArchive("archive file exceeds the size limit")
        total += member.size
        if total > MAX_TOTAL_BYTES or len(chosen) >= MAX_FILES:
            raise RejectedArchive("archive exceeds the extraction limit")
        chosen.append((member, parts))
    # Reject file/ancestor collisions before writing any member.
    for parts in seen:
        if any(parts[:i] in seen for i in range(1, len(parts))):
            raise RejectedArchive("archive file collides with a directory path")
    return chosen


def open_directory(parent_fd, name, *, owner=None, create=True):
    created = False
    if create:
        try:
            os.mkdir(name, 0o700, dir_fd=parent_fd)
            created = True
        except FileExistsError:
            pass
    try:
        fd = os.open(
            name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=parent_fd
        )
    except OSError as exc:
        if exc.errno in (errno.ELOOP, errno.ENOTDIR):
            raise RejectedArchive(
                "destination ancestor is not a real directory"
            ) from None
        raise
    if created and owner is not None:
        os.fchown(fd, *owner)
    return fd


def open_root(root, *, owner=None):
    path = PurePosixPath(root)
    if not path.is_absolute() or ".." in path.parts:
        raise RejectedArchive("destination root must be an absolute, normalized path")
    fd = os.open("/", os.O_RDONLY | os.O_DIRECTORY)
    try:
        for part in path.parts[1:]:
            next_fd = open_directory(fd, part, owner=owner)
            os.close(fd)
            fd = next_fd
        return fd
    except BaseException:
        os.close(fd)
        raise


def descendant_exists(root_fd, parts):
    fd = os.dup(root_fd)
    try:
        for part in parts[:-1]:
            try:
                next_fd = open_directory(fd, part, create=False)
            except FileNotFoundError:
                return False
            os.close(fd)
            fd = next_fd
        try:
            os.stat(parts[-1], dir_fd=fd, follow_symlinks=False)
            return True
        except FileNotFoundError:
            return False
    finally:
        os.close(fd)


def publish_file(archive, member, parts, root_fd, *, owner=None):
    parent_fd = os.dup(root_fd)
    temp_name = None
    try:
        for part in parts[:-1]:
            next_fd = open_directory(parent_fd, part, owner=owner)
            os.close(parent_fd)
            parent_fd = next_fd
        try:
            os.stat(parts[-1], dir_fd=parent_fd, follow_symlinks=False)
            return False
        except FileNotFoundError:
            pass
        temp_name = ".private-restore-" + secrets.token_hex(16)
        temp_fd = os.open(
            temp_name,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
            0o600,
            dir_fd=parent_fd,
        )
        with os.fdopen(temp_fd, "wb") as out:
            if owner is not None:
                os.fchown(out.fileno(), *owner)
            os.fchmod(out.fileno(), 0o600)
            remaining = member.size
            source = archive.extractfile(member)
            if source is None:
                raise RejectedArchive("regular archive file cannot be read")
            with source:
                while remaining:
                    chunk = source.read(min(1024 * 1024, remaining))
                    if not chunk:
                        raise RejectedArchive("truncated archive file")
                    out.write(chunk)
                    remaining -= len(chunk)
            out.flush()
            os.fsync(out.fileno())
        try:
            # Hard-link publication is atomic and fails if another writer has
            # already created the destination. rename() could overwrite it.
            os.link(
                temp_name,
                parts[-1],
                src_dir_fd=parent_fd,
                dst_dir_fd=parent_fd,
                follow_symlinks=False,
            )
        except FileExistsError:
            return False
        os.fsync(parent_fd)
        return True
    finally:
        if temp_name is not None:
            try:
                os.unlink(temp_name, dir_fd=parent_fd)
            except FileNotFoundError:
                pass
        os.close(parent_fd)


def restore(
    archive_path,
    root,
    *,
    prefix="",
    flat=False,
    allow_files=(),
    allow_suffixes=(),
    guards=(),
    owner=None,
):
    # A missing secret must not create directories or block unrelated public
    # Home Manager settings on a machine whose age key is not available yet.
    try:
        source_fd = os.open(archive_path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    except (FileNotFoundError, PermissionError):
        return {"unavailable": True, "created": 0, "existing": 0, "guarded": False}
    with os.fdopen(source_fd, "rb") as source:
        if not stat.S_ISREG(os.fstat(source.fileno()).st_mode):
            raise RejectedArchive("runtime archive is not a regular file")
        with tarfile.open(fileobj=source, mode="r:*") as archive:
            members = selected_members(
                archive,
                prefix=prefix,
                flat=flat,
                allow_files=allow_files,
                allow_suffixes=allow_suffixes,
            )
            guard_parts = [parts_for(name) for name in guards]
            root_fd = open_root(root, owner=owner)
            try:
                if any(descendant_exists(root_fd, parts) for parts in guard_parts):
                    return {
                        "unavailable": False,
                        "created": 0,
                        "existing": 0,
                        "guarded": True,
                    }
                created = sum(
                    publish_file(archive, member, parts, root_fd, owner=owner)
                    for member, parts in members
                )
                return {
                    "unavailable": False,
                    "created": created,
                    "existing": len(members) - created,
                    "guarded": False,
                }
            finally:
                os.close(root_fd)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", required=True)
    parser.add_argument("--root", required=True)
    parser.add_argument("--label", default="private-config")
    parser.add_argument("--strip-prefix", default="")
    parser.add_argument("--flat", action="store_true")
    parser.add_argument("--allow-file", action="append", default=[])
    parser.add_argument("--guard-file", action="append", default=[])
    parser.add_argument("--allow-suffix", action="append", default=[])
    parser.add_argument("--owner")
    args = parser.parse_args()
    owner = None
    if args.owner:
        user = pwd.getpwnam(args.owner)
        owner = (user.pw_uid, user.pw_gid)
        if os.geteuid() != 0 and owner[0] != os.geteuid():
            parser.error("changing owner requires root")
    try:
        result = restore(
            args.archive,
            args.root,
            prefix=args.strip_prefix,
            flat=args.flat,
            allow_files=args.allow_file,
            allow_suffixes=args.allow_suffix,
            guards=args.guard_file,
            owner=owner,
        )
    except (RejectedArchive, tarfile.TarError, OSError) as exc:
        # Do not include filenames from an archive in logs.
        print(
            f"{args.label}: private archive restore rejected ({type(exc).__name__})",
            file=sys.stderr,
        )
        return 1
    if result["unavailable"]:
        print(f"{args.label}: runtime secret unavailable; restore skipped")
    elif result["guarded"]:
        print(
            f"{args.label}: existing application state preserved; archive restore skipped"
        )
    else:
        print(
            f"{args.label}: restored {result['created']} file(s); preserved {result['existing']} existing file(s)"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
