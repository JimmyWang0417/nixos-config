#!/usr/bin/env python3
"""Check real session environment scripts and safe dictionary initialization."""

import importlib.util
import io
import json
import os
from pathlib import Path
import stat
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location(
    "restore_dictionary", ROOT / "home/fcitx5/restore-dictionary.py"
)
restore = importlib.util.module_from_spec(spec)
spec.loader.exec_module(restore)


class SessionEnvironmentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        result = subprocess.run(
            [
                "nix",
                "eval",
                "--impure",
                "--json",
                "--no-update-lock-file",
                "--file",
                "tests/input-method.nix",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        if result.returncode:
            raise AssertionError(result.stderr)
        cls.configuration = json.loads(result.stdout)

    def environment_for(self, session):
        script = (
            self.configuration["sessionScript"]
            + r"""
for name in GTK_IM_MODULE QT_IM_MODULE SDL_IM_MODULE ELECTRON_OZONE_PLATFORM_HINT; do
    printf '%s=%s\n' "$name" "${!name-<unset>}"
done
"""
        )
        result = subprocess.run(
            ["bash", "-c", script],
            check=True,
            capture_output=True,
            text=True,
            env={
                "PATH": os.defpath,
                "XDG_SESSION_TYPE": session,
                "GTK_IM_MODULE": "ibus",
                "QT_IM_MODULE": "ibus",
                "SDL_IM_MODULE": "ibus",
                "ELECTRON_OZONE_PLATFORM_HINT": "wayland",
            },
        )
        return dict(line.split("=", 1) for line in result.stdout.splitlines())

    def test_wayland_clears_inherited_x11_modules(self):
        values = self.environment_for("wayland")
        for name in ("GTK_IM_MODULE", "QT_IM_MODULE", "SDL_IM_MODULE"):
            self.assertEqual(values[name], "<unset>")
        self.assertEqual(values["ELECTRON_OZONE_PLATFORM_HINT"], "auto")

    def test_xfce_x11_selects_fcitx_without_wayland_hint(self):
        values = self.environment_for("x11")
        for name in ("GTK_IM_MODULE", "QT_IM_MODULE", "SDL_IM_MODULE"):
            self.assertEqual(values[name], "fcitx")
        self.assertEqual(values["ELECTRON_OZONE_PLATFORM_HINT"], "<unset>")


class DictionaryTests(unittest.TestCase):
    def archive(self, root, *, symlink=False):
        path = root / "dictionary.tar"
        with tarfile.open(path, "w") as archive:
            for name in ("user.dict", "user.history"):
                entry = tarfile.TarInfo(name)
                if symlink and name == "user.dict":
                    entry.type = tarfile.SYMTYPE
                    entry.linkname = "../../outside"
                    archive.addfile(entry)
                else:
                    content = ("saved " + name).encode()
                    entry.size = len(content)
                    archive.addfile(entry, io.BytesIO(content))
            malicious = tarfile.TarInfo("../outside")
            malicious.size = 6
            archive.addfile(malicious, io.BytesIO(b"escape"))
        return path

    def test_initialization_is_private_and_preserves_new_learning(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            archive = self.archive(root)
            data = root / "pinyin"
            self.assertEqual(
                restore.restore_dictionary(archive, data), ["user.dict", "user.history"]
            )
            self.assertEqual(stat.S_IMODE((data / "user.dict").stat().st_mode), 0o600)
            self.assertEqual((data / "user.dict").read_bytes(), b"saved user.dict")
            (data / "user.dict").write_bytes(b"newly learned words")
            self.assertEqual(restore.restore_dictionary(archive, data), [])
            self.assertEqual((data / "user.dict").read_bytes(), b"newly learned words")
            self.assertFalse((root / "outside").exists())

    def test_existing_symlink_is_not_replaced_or_followed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            archive = self.archive(root)
            data = root / "pinyin"
            data.mkdir()
            outside = root / "existing"
            outside.write_bytes(b"personal data")
            (data / "user.dict").symlink_to(outside)
            self.assertEqual(
                restore.restore_dictionary(archive, data), ["user.history"]
            )
            self.assertTrue((data / "user.dict").is_symlink())
            self.assertEqual(outside.read_bytes(), b"personal data")

    def test_complete_publication_preserves_a_concurrent_writer(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            archive = self.archive(root)
            data = root / "pinyin"
            copy_file = restore.shutil.copyfileobj
            copied = []

            def concurrent_copy(source, output):
                name = ("user.dict", "user.history")[len(copied)]
                # The engine must never see a half-written archive file.
                self.assertFalse((data / name).exists())
                if name == "user.dict":
                    (data / name).write_bytes(b"concurrently learned words")
                copy_file(source, output)
                copied.append(name)

            with patch.object(restore.shutil, "copyfileobj", concurrent_copy):
                self.assertEqual(
                    restore.restore_dictionary(archive, data), ["user.history"]
                )
            self.assertEqual(
                (data / "user.dict").read_bytes(), b"concurrently learned words"
            )
            self.assertEqual(
                (data / "user.history").read_bytes(), b"saved user.history"
            )
            self.assertEqual(list(data.glob(".fcitx-dictionary-*")), [])

    def test_archive_symlinks_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaises(ValueError):
                restore.restore_dictionary(
                    self.archive(root, symlink=True), root / "pinyin"
                )
            self.assertFalse((root / "outside").exists())

    def test_missing_secret_does_not_create_data(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertEqual(
                restore.restore_dictionary(root / "missing", root / "pinyin"), []
            )
            self.assertFalse((root / "pinyin").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
