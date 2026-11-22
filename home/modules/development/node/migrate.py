"""Move legacy Node/npm state without reading credentials or replacing targets."""

import argparse
import ctypes
import errno
import fcntl
import json
import os
from pathlib import Path


def existing(path):
    return path.exists() or path.is_symlink()


def has_symlink(path):
    return any(part.is_symlink() for part in [path, *path.parents])


def active_references(paths):
    roots = [str(path) for path in paths]
    matches = []
    for process in Path("/proc").iterdir():
        if not process.name.isdigit() or int(process.name) == os.getpid():
            continue
        try:
            if process.stat().st_uid != os.getuid():
                continue
            command = (process / "cmdline").read_bytes().split(b"\0")
            links = [os.readlink(process / "exe"), os.readlink(process / "cwd")]
            if any(
                any(
                    str(value).startswith(root + "/") or str(value) == root
                    for value in links
                )
                or any(
                    root.encode() + b"/" in argument or root.encode() == argument
                    for argument in command
                )
                for root in roots
            ):
                matches.append(int(process.name))
        except (FileNotFoundError, PermissionError, ProcessLookupError):
            continue
    return sorted(matches)


def rename_noreplace(source, target):
    # Linux renameat2 prevents a target created after our check being replaced.
    libc = ctypes.CDLL(None, use_errno=True)
    if not hasattr(libc, "renameat2"):
        raise OSError(errno.ENOSYS, "renameat2 is required for a non-overwriting move")
    rename = libc.renameat2
    rename.argtypes = [
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_uint,
    ]
    rename.restype = ctypes.c_int
    if rename(-100, os.fsencode(source), -100, os.fsencode(target), 1) != 0:
        number = ctypes.get_errno()
        raise OSError(number, os.strerror(number))


def move_one(source, target, kind, dry_run=False):
    result = {"source": str(source), "target": str(target)}
    if has_symlink(source) or has_symlink(target):
        return result | {"status": "preserved-symlink"}
    if existing(source) and existing(target):
        return result | {"status": "preserved-conflict"}
    if existing(target) and not (
        target.is_dir() if kind == "directory" else target.is_file()
    ):
        return result | {"status": "preserved-special-file"}
    if existing(source) and not (
        source.is_dir() if kind == "directory" else source.is_file()
    ):
        return result | {"status": "preserved-special-file"}
    if dry_run:
        return result | {
            "status": "would-move"
            if existing(source)
            else "would-initialize"
            if not existing(target)
            else "present"
        }
    if existing(source):
        target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        try:
            # Rename is atomic and retains permissions, links, timestamps and inodes.
            # Never fall back to recursive copying across filesystems.
            rename_noreplace(source, target)
        except OSError as error:
            if error.errno == errno.EXDEV:
                return result | {"status": "preserved-cross-filesystem"}
            if error.errno == errno.EEXIST:
                return result | {"status": "preserved-conflict"}
            if error.errno == errno.ENOSYS:
                return result | {"status": "preserved-unsupported-rename"}
            raise
        if kind == "private-file":
            target.chmod(0o600)
        return result | {"status": "moved"}
    if not existing(target):
        target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        if kind == "directory":
            target.mkdir(mode=0o700)
        else:
            # Exclusive creation prevents replacing a concurrently created config.
            descriptor = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            os.close(descriptor)
        return result | {"status": "initialized"}
    return result | {"status": "present"}


def migrate(home, config, cache, data, state, dry_run=False):
    paths = [
        (home / ".npm", cache / "npm", "directory"),
        (home / ".npm-global", data / "npm", "directory"),
        (home / ".npmrc", config / "npm/npmrc", "private-file"),
        (home / ".node_repl_history", state / "node/repl_history", "private-file"),
    ]
    if any(not path.is_absolute() for pair in paths for path in pair[:2]):
        raise ValueError("Migration roots must be absolute")
    if dry_run:
        return [move_one(*row, dry_run=True) for row in paths]
    processes = active_references([source for source, _, _ in paths])
    if processes:
        return [{"status": "preserved-active-process", "processIds": processes}]
    lock_parent = state / "node"
    if has_symlink(lock_parent):
        return [{"status": "preserved-symlink", "target": str(lock_parent)}]
    lock_parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    lock = lock_parent / "migration.lock"
    descriptor = os.open(lock, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    with os.fdopen(descriptor, "a") as stream:
        fcntl.flock(stream, fcntl.LOCK_EX)
        return [move_one(*row) for row in paths]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["home", "config", "cache", "data", "state"]:
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    result = migrate(
        args.home, args.config, args.cache, args.data, args.state, args.dry_run
    )
    # Only statuses and paths. Never include npmrc contents, environment or tokens.
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
