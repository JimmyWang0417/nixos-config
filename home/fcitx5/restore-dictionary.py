#!/usr/bin/env python3
"""Initialize missing Fcitx dictionary files from the decrypted sops archive.

No extraction paths come from archive member names. Existing learned data and
symlinks are never replaced, and plaintext never enters the repository/store.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import secrets
import shutil
import tarfile


def restore_dictionary(archive: Path, data_dir: Path) -> list[str]:
    if not archive.is_file():
        return []
    restored = []
    with tarfile.open(archive, mode="r:*") as source:
        members = source.getmembers()
        selected = []
        for name in ("user.dict", "user.history"):
            matches = [member for member in members if member.name == name]
            if len(matches) != 1 or not matches[0].isfile():
                raise ValueError(f"Expected one regular {name} in the Fcitx archive")
            member = matches[0]
            if member.size > 128 * 1024 * 1024:
                raise ValueError(f"Fcitx archive member {name} exceeds 128 MiB")
            selected.append((name, member))

        data_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
        directory = os.open(data_dir, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        try:
            for name, member in selected:
                try:
                    os.stat(name, dir_fd=directory, follow_symlinks=False)
                    continue
                except FileNotFoundError:
                    pass
                temporary = ".fcitx-dictionary-" + secrets.token_hex(16)
                descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                                     0o600, dir_fd=directory)
                try:
                    with os.fdopen(descriptor, "wb") as output, source.extractfile(member) as data:
                        shutil.copyfileobj(data, output)
                        output.flush()
                        os.fsync(output.fileno())
                    try:
                        # Publish only complete files. A concurrently started
                        # Fcitx may have created its own learned data meanwhile;
                        # link() preserves it instead of replacing it.
                        os.link(temporary, name, src_dir_fd=directory, dst_dir_fd=directory,
                                follow_symlinks=False)
                    except FileExistsError:
                        continue
                    os.fsync(directory)
                    restored.append(name)
                finally:
                    os.unlink(temporary, dir_fd=directory)
        finally:
            os.close(directory)
    return restored


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--data-dir", type=Path, required=True)
    args = parser.parse_args()
    if not args.archive.is_file():
        print("Fcitx dictionary secret is unavailable; keeping existing learned data.")
        return
    restored = restore_dictionary(args.archive, args.data_dir)
    print("Fcitx dictionaries initialized: " + (", ".join(restored) if restored else "existing data preserved"))


if __name__ == "__main__":
    main()
