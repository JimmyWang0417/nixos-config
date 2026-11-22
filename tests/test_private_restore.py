"""Exercise credential restore safety with artificial, nonsecret fixtures."""
import importlib.util
import io
import os
from pathlib import Path
import stat
import tarfile
import tempfile
import unittest
from unittest import mock

SPEC = importlib.util.spec_from_file_location(
    "restore_private_archive", Path(__file__).resolve().parents[1] / "lib/restore-private-archive.py"
)
restore = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(restore)

class PrivateRestoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.root = self.base / "destination"
        self.archive = self.base / "fixture.tar"

    def tearDown(self):
        self.temp.cleanup()

    def tar(self, entries):
        with tarfile.open(self.archive, "w") as out:
            for name, content in entries:
                if isinstance(content, tarfile.TarInfo):
                    item = content
                    item.name = name
                    out.addfile(item)
                else:
                    item = tarfile.TarInfo(name)
                    item.size = len(content)
                    item.mode = 0o777
                    out.addfile(item, io.BytesIO(content))

    def test_private_modes_and_idempotent_existing_files(self):
        self.tar([("nested/settings.ini", b"fixture")])
        result = restore.restore(self.archive, str(self.root))
        target = self.root / "nested/settings.ini"
        self.assertEqual(result["created"], 1)
        self.assertEqual(target.read_bytes(), b"fixture")
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE(target.parent.stat().st_mode), 0o700)
        target.write_bytes(b"user changes")
        target.chmod(0o640)
        result = restore.restore(self.archive, str(self.root))
        self.assertEqual(result["existing"], 1)
        self.assertEqual(target.read_bytes(), b"user changes")
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)

    def test_missing_secret_does_not_create_destination(self):
        result = restore.restore(self.archive, str(self.root))
        self.assertTrue(result["unavailable"])
        self.assertFalse(self.root.exists())

    def test_guard_preserves_whole_encryption_state(self):
        self.tar([(".encryption_key", b"archived key"), ("profiles.yaml", b"archive index")])
        self.root.mkdir()
        (self.root / ".encryption_key").write_bytes(b"existing key")
        result = restore.restore(self.archive, str(self.root), guards=[".encryption_key"])
        self.assertTrue(result["guarded"])
        self.assertEqual((self.root / ".encryption_key").read_bytes(), b"existing key")
        self.assertFalse((self.root / "profiles.yaml").exists())

    def test_rejects_traversal_before_publishing_any_file(self):
        for name in ["../outside", "/absolute", "a/../../outside", "C:/drive", "a\\b"]:
            with self.subTest(name=name):
                self.tar([("safe", b"first"), (name, b"blocked")])
                with self.assertRaises(restore.RejectedArchive):
                    restore.restore(self.archive, str(self.root))
                self.assertFalse(self.root.exists())

    def test_rejects_links_and_special_members_before_writing(self):
        for kind in [tarfile.SYMTYPE, tarfile.LNKTYPE, tarfile.FIFOTYPE, tarfile.CHRTYPE, tarfile.BLKTYPE]:
            with self.subTest(kind=kind):
                item = tarfile.TarInfo("unsafe")
                item.type = kind
                item.linkname = "../outside"
                self.tar([("safe", b"first"), ("unsafe", item)])
                with self.assertRaises(restore.RejectedArchive):
                    restore.restore(self.archive, str(self.root))
                self.assertFalse(self.root.exists())

    def test_rejects_duplicate_and_file_parent_collisions(self):
        for entries in [[("same", b"one"), ("same", b"two")], [("parent", b"one"), ("parent/child", b"two")]]:
            self.tar(entries)
            with self.assertRaises(restore.RejectedArchive):
                restore.restore(self.archive, str(self.root))
            self.assertFalse(self.root.exists())

    def test_rejects_destination_symlink_ancestors(self):
        self.tar([("nested/file", b"blocked")])
        self.root.mkdir()
        outside = self.base / "outside"
        outside.mkdir()
        (self.root / "nested").symlink_to(outside, target_is_directory=True)
        with self.assertRaises(restore.RejectedArchive):
            restore.restore(self.archive, str(self.root))
        self.assertFalse((outside / "file").exists())

    def test_rejects_symlink_root(self):
        self.tar([("file", b"blocked")])
        outside = self.base / "outside"
        outside.mkdir()
        self.root.symlink_to(outside, target_is_directory=True)
        with self.assertRaises(restore.RejectedArchive):
            restore.restore(self.archive, str(self.root))
        self.assertFalse((outside / "file").exists())

    def test_preserves_existing_destination_symlink(self):
        self.tar([("file", b"blocked")])
        self.root.mkdir()
        outside = self.base / "outside"
        outside.write_bytes(b"untouched")
        (self.root / "file").symlink_to(outside)
        result = restore.restore(self.archive, str(self.root))
        self.assertEqual(result["existing"], 1)
        self.assertEqual(outside.read_bytes(), b"untouched")

    def test_atomic_publish_preserves_racing_writer(self):
        self.tar([("file", b"archive value")])
        original_link = os.link
        def race(source, destination, **kwargs):
            fd = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL,
                         0o600, dir_fd=kwargs["dst_dir_fd"])
            with os.fdopen(fd, "wb") as output:
                output.write(b"racing writer")
            return original_link(source, destination, **kwargs)
        with mock.patch.object(restore.os, "link", side_effect=race):
            result = restore.restore(self.archive, str(self.root))
        self.assertEqual(result["existing"], 1)
        self.assertEqual((self.root / "file").read_bytes(), b"racing writer")
        self.assertEqual(list(self.root.glob(".private-restore-*")), [])

    def test_failure_does_not_publish_partial_file(self):
        self.tar([("file", b"archive value")])
        with mock.patch.object(restore.os, "fsync", side_effect=OSError("fixture failure")):
            with self.assertRaises(OSError):
                restore.restore(self.archive, str(self.root))
        self.assertFalse((self.root / "file").exists())
        self.assertEqual(list(self.root.glob(".private-restore-*")), [])

    def test_exact_file_flat_suffix_and_prefix_policies(self):
        self.tar([("prefix/profile.nmconnection", b"fixture")])
        result = restore.restore(self.archive, str(self.root), prefix="prefix", flat=True,
                                 allow_files=["profile.nmconnection"], allow_suffixes=[".nmconnection"])
        self.assertEqual(result["created"], 1)
        for policy in [{"flat": True}, {"allow_files": ["different"]}, {"prefix": "other"}, {"allow_suffixes": [".json"]}]:
            with self.subTest(policy=policy):
                with self.assertRaises(restore.RejectedArchive):
                    restore.restore(self.archive, str(self.root), **policy)

    def test_size_and_member_limits_are_checked_before_writing(self):
        self.tar([("one", b"large fixture")])
        with mock.patch.object(restore, "MAX_FILE_BYTES", 2):
            with self.assertRaises(restore.RejectedArchive):
                restore.restore(self.archive, str(self.root))
        self.assertFalse(self.root.exists())
        self.tar([("one", b"1"), ("two", b"2")])
        with mock.patch.object(restore, "MAX_FILES", 1):
            with self.assertRaises(restore.RejectedArchive):
                restore.restore(self.archive, str(self.root))
        self.assertFalse(self.root.exists())

if __name__ == "__main__":
    unittest.main()
