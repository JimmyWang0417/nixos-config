#!/usr/bin/env python3
"""Exercise packaged Ark and its private libzip using isolated temporary data."""

import ctypes
import io
import os
from pathlib import Path
import struct
import subprocess
import sys
import tarfile
import tempfile
import unittest
import zipfile
import zlib


class RawNameInfo(zipfile.ZipInfo):
    """Preserve exact legacy ZIP header bytes instead of Python's UTF-8 encoding."""

    def __init__(self, name, raw, *, utf8_flag=False, unicode_extra=None):
        super().__init__(name, date_time=(2020, 1, 1, 0, 0, 0))
        self.raw_name = raw
        self.utf8_flag = utf8_flag
        self.create_system = 0  # Windows/FAT-origin archive, not a Unix creator.
        self.external_attr = 0x10 if name.endswith("/") else 0x20
        if unicode_extra is not None:
            value = (
                b"\x01"
                + struct.pack("<I", zlib.crc32(raw))
                + unicode_extra.encode("utf-8")
            )
            self.extra = struct.pack("<HH", 0x7075, len(value)) + value

    def _encodeFilenameFlags(self):
        flags = self.flag_bits & ~0x800
        return self.raw_name, flags | (0x800 if self.utf8_flag else 0)


def fixture(path, entries):
    """Entries are (expected Unicode name, raw header bytes, flags, extra, payload)."""
    expected = {}
    with zipfile.ZipFile(path, "w") as archive:
        for name, raw, utf8, extra, payload in entries:
            info = RawNameInfo(name, raw, utf8_flag=utf8, unicode_extra=extra)
            archive.writestr(info, payload)
            if not name.endswith("/"):
                expected[name] = payload
    return expected


class ArkArchiveTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        for variable in [
            "ARK_BIN",
            "ARK_PLUGIN_DIR",
            "ARK_PRIVATE_LIBZIP",
            "ARK_MIME_DATA_DIR",
            "SEVENZIP_BIN",
        ]:
            if not os.environ.get(variable):
                raise AssertionError(
                    f"{variable} must point to the packaged test dependency"
                )
        cls.ark = os.environ["ARK_BIN"]
        cls.sevenzip = os.environ["SEVENZIP_BIN"]
        cls.libzip = ctypes.CDLL(os.environ["ARK_PRIVATE_LIBZIP"])
        cls.libzip.zip_open.argtypes = [
            ctypes.c_char_p,
            ctypes.c_int,
            ctypes.POINTER(ctypes.c_int),
        ]
        cls.libzip.zip_open.restype = ctypes.c_void_p
        cls.libzip.zip_close.argtypes = [ctypes.c_void_p]
        cls.libzip.zip_close.restype = ctypes.c_int
        cls.libzip.zip_name_locate.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
            ctypes.c_uint,
        ]
        cls.libzip.zip_name_locate.restype = ctypes.c_int64
        cls.libzip.zip_get_name.argtypes = [
            ctypes.c_void_p,
            ctypes.c_uint64,
            ctypes.c_uint,
        ]
        cls.libzip.zip_get_name.restype = ctypes.c_char_p
        cls.libzip.zip_fopen_index.argtypes = [
            ctypes.c_void_p,
            ctypes.c_uint64,
            ctypes.c_uint,
        ]
        cls.libzip.zip_fopen_index.restype = ctypes.c_void_p
        cls.libzip.zip_fopen.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
            ctypes.c_uint,
        ]
        cls.libzip.zip_fopen.restype = ctypes.c_void_p
        cls.libzip.zip_fread.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_uint64,
        ]
        cls.libzip.zip_fread.restype = ctypes.c_int64
        cls.libzip.zip_fclose.argtypes = [ctypes.c_void_p]
        cls.libzip.zip_fclose.restype = ctypes.c_int

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="ark-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.environment = os.environ.copy()
        for variable, directory in [
            ("XDG_CONFIG_HOME", "config"),
            ("XDG_DATA_HOME", "data"),
            ("XDG_STATE_HOME", "state"),
            ("XDG_CACHE_HOME", "cache"),
            ("XDG_RUNTIME_DIR", "runtime"),
            ("XDG_CONFIG_DIRS", "config-dirs"),
        ]:
            path = self.root / directory
            path.mkdir(mode=0o700)
            self.environment[variable] = str(path)
        self.environment.update(
            # Backend availability must come from Ark's own wrapper. Inheriting
            # host /usr/bin/7z or unrar would hide a broken Nix wrapper.
            PATH=str(Path(sys.executable).parent),
            # NixOS normally supplies the shared MIME database through its
            # profile. Supply that exact dependency, never the host's database.
            XDG_DATA_DIRS=os.environ["ARK_MIME_DATA_DIR"],
            QT_QPA_PLATFORM="offscreen",
            LC_ALL="C.UTF-8",
            DBUS_SESSION_BUS_ADDRESS=f"unix:path={self.root}/no-session-bus",
            DBUS_SYSTEM_BUS_ADDRESS=f"unix:path={self.root}/no-system-bus",
        )

    def run_tool(self, command):
        result = subprocess.run(
            command,
            cwd=self.root,
            env=self.environment,
            capture_output=True,
            timeout=30,
        )
        self.assertEqual(
            result.returncode,
            0,
            result.stdout.decode("utf-8", "replace")
            + result.stderr.decode("utf-8", "replace"),
        )
        return result

    def extract(self, archive, expected):
        destination = self.root / "extracted"
        destination.mkdir()
        self.run_tool(
            [self.ark, "--batch", "--destination", str(destination), str(archive)]
        )
        found = {
            str(path.relative_to(destination)): path.read_bytes()
            for path in destination.rglob("*")
            if path.is_file()
        }
        self.assertEqual(found, expected)

    def check_zip(self, name, encoding, *, utf8=False, unicode_extra=None):
        archive = self.root / "input.zip"
        raw = name.encode(encoding)
        expected = fixture(
            archive, [(name, raw, utf8, unicode_extra, b"payload\x00unchanged\xff\n")]
        )
        self.extract(archive, expected)

    def test_gbk_windows_filename_and_nested_path(self):
        self.check_zip("中文目录/简体测试.txt", "gbk")

    def test_gb18030_four_byte_characters_in_whole_path(self):
        self.check_zip("中文𠮷目录/文档𠀀.txt", "gb18030")

    def test_standard_utf8_flag_is_preserved(self):
        self.check_zip("正常目录/UTF8测试𠮷.txt", "utf-8", utf8=True)

    def test_valid_utf8_without_flag_is_preserved(self):
        self.check_zip("未标记UTF8/中文𠮷.txt", "utf-8")

    def test_unicode_path_extra_field_takes_precedence(self):
        archive = self.root / "unicode-extra.zip"
        name = "明确Unicode/文件𠮷.txt"
        expected = fixture(
            archive, [(name, b"legacy-name.txt", False, name, b"unicode-extra\n")]
        )
        self.extract(archive, expected)

    def test_invalid_gb18030_falls_back_to_cp437(self):
        self.check_zip("café.txt", "cp437")

    def test_mixed_zip_and_selected_unicode_name_lookup(self):
        archive = self.root / "mixed.zip"
        legacy = "GBK目录/内层/内容.txt"
        large = "GB18030𠮷目录/选中文件𠀀.txt"
        utf8 = "UTF8目录/文件𠮷.txt"
        extra = "Unicode字段/名字.txt"
        expected = fixture(
            archive,
            [
                ("GBK目录/", "GBK目录/".encode("gbk"), False, None, b""),
                (legacy, legacy.encode("gbk"), False, None, b"selected-gbk\x00\xff"),
                (
                    large,
                    large.encode("gb18030"),
                    False,
                    None,
                    b"selected-gb18030\x00\xff",
                ),
                (utf8, utf8.encode("utf-8"), True, None, b"normal-utf8"),
                (extra, b"legacy-extra.txt", False, extra, b"unicode-extra"),
                ("README.txt", b"README.txt", False, None, b"plain-ascii"),
                ("café.txt", "café.txt".encode("cp437"), False, None, b"cp437"),
            ],
        )
        self.extract(archive, expected)
        error = ctypes.c_int()
        handle = self.libzip.zip_open(os.fsencode(archive), 16, ctypes.byref(error))
        self.assertTrue(handle, f"zip_open error {error.value}")
        try:
            # Ark/libzip selects listed entries by Unicode filename. Check that
            # the same name maps back to the correct index and original bytes.
            for name, payload in expected.items():
                index = self.libzip.zip_name_locate(handle, name.encode("utf-8"), 0)
                self.assertGreaterEqual(index, 0, name)
                self.assertEqual(
                    self.libzip.zip_get_name(handle, index, 0).decode("utf-8"), name
                )
                if name in [legacy, large]:
                    encoding = "gbk" if name == legacy else "gb18030"
                    self.assertEqual(
                        self.libzip.zip_get_name(handle, index, 64),
                        name.encode(encoding),
                    )
                for selected_by in ["index", "name"]:
                    file_handle = (
                        self.libzip.zip_fopen_index(handle, index, 0)
                        if selected_by == "index"
                        else self.libzip.zip_fopen(handle, name.encode("utf-8"), 0)
                    )
                    self.assertTrue(file_handle, (name, selected_by))
                    try:
                        buffer = ctypes.create_string_buffer(len(payload) + 1)
                        count = self.libzip.zip_fread(
                            file_handle, buffer, len(payload) + 1
                        )
                        self.assertEqual(count, len(payload), (name, selected_by))
                        self.assertEqual(
                            buffer.raw[:count], payload, (name, selected_by)
                        )
                    finally:
                        self.assertEqual(self.libzip.zip_fclose(file_handle), 0)
        finally:
            self.assertEqual(self.libzip.zip_close(handle), 0)

    def test_native_libarchive_tar_extraction(self):
        archive = self.root / "input.tar"
        name = "普通目录/文本𠮷.txt"
        payload = b"native-libarchive\x00\xff"
        with tarfile.open(archive, "w") as tar:
            info = tarfile.TarInfo(name)
            info.size = len(payload)
            tar.addfile(info, io.BytesIO(payload))
        self.extract(archive, {name: payload})

    def test_cli7z_backend_creates_and_extracts_7z(self):
        source = self.root / "中文目录"
        source.mkdir()
        payload = b"native-sevenzip\x00\xff"
        (source / "文件𠮷.txt").write_bytes(payload)
        archive = self.root / "input.7z"
        self.run_tool([self.sevenzip, "a", str(archive), str(source)])
        # Libarchive can also read 7z. Disable that fallback only for this
        # isolated test so a missing private `7z` executable cannot go unnoticed.
        (self.root / "config/arkrc").write_text(
            "[Plugins]\ndisabledPlugins=kerfuffle_libarchive,kerfuffle_libarchive_readonly\n"
        )
        self.extract(archive, {"中文目录/文件𠮷.txt": payload})

    def test_ark_zip_creation_keeps_standard_utf8_and_roundtrips(self):
        source = self.root / "source"
        source.mkdir()
        name = "新建中文𠮷.txt"
        payload = b"created-by-ark\x00\xff"
        path = source / name
        path.write_bytes(payload)
        archive = self.root / "created.zip"
        self.run_tool(
            [self.ark, "--changetofirstpath", "--add-to", str(archive), str(path)]
        )
        with zipfile.ZipFile(archive) as created:
            self.assertEqual(created.namelist(), [name])
            self.assertTrue(created.getinfo(name).flag_bits & 0x800)
            self.assertEqual(created.read(name), payload)
        self.extract(archive, {name: payload})

    def test_plugin_files_and_supported_mimetypes(self):
        plugins = Path(os.environ["ARK_PLUGIN_DIR"])
        for plugin in [
            "kerfuffle_libzip",
            "kerfuffle_libarchive",
            "kerfuffle_libarchive_readonly",
            "kerfuffle_cli7z",
            "kerfuffle_clirar",
            "kerfuffle_cliunarchiver",
        ]:
            self.assertTrue((plugins / (plugin + ".so")).is_file(), plugin)
        result = self.run_tool([self.ark, "--mimetypes"])
        mimetypes = result.stdout.decode("utf-8")
        for mimetype in [
            "application/zip",
            "application/x-tar",
            "application/x-7z-compressed",
        ]:
            self.assertIn(mimetype, mimetypes)
        self.assertTrue(
            "application/vnd.rar" in mimetypes or "application/x-rar" in mimetypes
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
