#!/usr/bin/env python3
"""Inspect vendor clients and resolve ELF dependencies without launching clients."""

import json
import os
from pathlib import Path
import re
import subprocess
import unittest

# This exact Python 3.6 binary is a vendored node-gyp build artifact, not part of
# the Baidu client's runtime. Do not broadly skip arbitrary executable subtrees.
BUILD_ARTIFACT = "resources/app.asar.unpacked/node_modules/windows-quiet-hours/build/node_gyp_bins/python3"
REPORT = {
    "method": "ELF metadata and current glibc loader --list; no vendor entrypoint execution",
    "resolved": [],
    "excluded": [],
}


def elf(path):
    if not path.is_file():
        return False
    with path.open("rb") as stream:
        return stream.read(4) == b"\x7fELF"


def readelf(path):
    process = subprocess.run(
        ["readelf", "--dynamic", "--wide", str(path)],
        capture_output=True,
        text=True,
        timeout=30,
    )
    if process.returncode:
        raise AssertionError(process.stdout + process.stderr)
    return process.stdout


class NativeClientChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        required = [
            "CLIENT_DYNAMIC_LOADER",
            "CLIENT_GLIBC",
            "CLIENT_GLIBC_OUTPUTS",
            "CLIENT_CXX_RUNTIME",
            "CLIENT_CLOSURE_PATHS",
            "CLIENT_BASH",
            "BAIDU_ROOT",
            "BAIDU_UNWRAPPED",
            "BAIDU_GTKMM",
            "BAIDU_LIBRARY_PATH",
            "FCITX_GTK_ROOT",
            "APPINDICATOR_LIBRARY",
            "DINGTALK_ROOT",
            "DINGTALK_SCREENSHARE",
            "DINGTALK_KNOWN_VULNERABILITIES",
        ]
        for variable in required:
            if not os.environ.get(variable):
                raise AssertionError(f"Missing Nix test dependency: {variable}")
        cls.loader = os.environ["CLIENT_DYNAMIC_LOADER"]
        cls.glibc = Path(os.environ["CLIENT_GLIBC"])
        cls.libc = (cls.glibc / "lib/libc.so.6").resolve()
        cls.cxx = Path(os.environ["CLIENT_CXX_RUNTIME"]).resolve()
        cls.baidu = Path(os.environ["BAIDU_UNWRAPPED"]) / "opt/baidunetdisk"
        cls.library_path = str(cls.baidu) + ":" + os.environ["BAIDU_LIBRARY_PATH"]
        cls.dingtalk = Path(os.environ["DINGTALK_ROOT"])
        cls.closure = set(
            Path(os.environ["CLIENT_CLOSURE_PATHS"]).read_text().splitlines()
        )

    def resolve(self, path):
        self.assertTrue(elf(path), str(path))
        # Use an explicit loader and library path, not ldd or the binary's
        # interpreter. --list resolves DT_NEEDED without calling the entrypoint.
        environment = os.environ.copy()
        environment.pop("LD_PRELOAD", None)
        environment.pop("LD_LIBRARY_PATH", None)
        process = subprocess.run(
            [
                self.loader,
                "--inhibit-cache",
                "--library-path",
                self.library_path,
                "--list",
                str(path),
            ],
            env=environment,
            capture_output=True,
            text=True,
            timeout=30,
        )
        output = process.stdout + process.stderr
        self.assertEqual(process.returncode, 0, f"{path}\n{output}")
        self.assertNotIn("not found", output, str(path))
        libraries = dict(re.findall(r"^\s*(\S+) => (/[^(\s]+)", output, re.MULTILINE))
        for name, target in libraries.items():
            resolved = Path(target).resolve()
            match = re.match(r"(/nix/store/[^/]+)", str(resolved))
            self.assertIsNotNone(match, f"Foreign runtime path for {name}: {resolved}")
            self.assertIn(
                match.group(1),
                self.closure,
                f"Dependency outside actual client closure: {resolved}",
            )
            if name == "libc.so.6":
                self.assertEqual(resolved, self.libc, f"Mixed glibc in {path}")
            elif name == "libstdc++.so.6":
                self.assertEqual(
                    resolved, self.cxx, f"Mixed compiler runtime in {path}"
                )
        REPORT["resolved"].append(
            {"file": str(path), "status": "pass", "libraries": libraries}
        )
        return libraries

    def test_client_closure_uses_only_current_glibc(self):
        glibc_roots = {
            path for path in self.closure if re.search(r"-glibc-[0-9]", path)
        }
        # The FHS environment also needs getent/ldconfig from the matching bin
        # output; that is the same libc build, not a foreign glibc version.
        self.assertTrue(
            glibc_roots <= set(json.loads(os.environ["CLIENT_GLIBC_OUTPUTS"])),
            glibc_roots,
        )
        self.assertIn(str(self.glibc), glibc_roots)
        self.assertTrue((Path(os.environ["BAIDU_ROOT"]) / "bin/baidunetdisk").is_file())
        self.assertTrue(
            (Path(os.environ["BAIDU_GTKMM"]) / "lib/libgtkmm-2.4.so.1").is_file()
        )

    def test_all_baidu_runtime_elf_dependencies_resolve(self):
        checked = []
        for path in sorted(self.baidu.rglob("*")):
            if not elf(path):
                continue
            relative = str(path.relative_to(self.baidu))
            if relative == BUILD_ARTIFACT:
                REPORT["excluded"].append(
                    {
                        "file": relative,
                        "reason": "Vendored node-gyp Python 3.6 build artifact; not a client runtime entrypoint.",
                    }
                )
                continue
            with self.subTest(file=relative):
                self.resolve(path)
                checked.append(relative)
        self.assertIn("baidunetdisk", checked)
        self.assertIn("libbrowserengine.so", checked)
        self.assertGreaterEqual(len(checked), 15)
        self.assertEqual(
            [item["file"] for item in REPORT["excluded"]], [BUILD_ARTIFACT]
        )

    def test_fcitx_gtk2_gtk3_gtk4_modules_resolve(self):
        root = Path(os.environ["FCITX_GTK_ROOT"]) / "lib"
        for abi in ["gtk-2.0", "gtk-3.0", "gtk-4.0"]:
            modules = list((root / abi).glob("*/immodules/*fcitx*.so"))
            self.assertTrue(modules, f"Missing Fcitx module for {abi}")
            for module in modules:
                with self.subTest(abi=abi, module=str(module)):
                    self.resolve(module)

    def test_gtk3_indicator_and_dbusmenu_resolve(self):
        libraries = self.resolve(Path(os.environ["APPINDICATOR_LIBRARY"]))
        self.assertIn("libgtk-3.so.0", libraries)
        self.assertIn("libdbusmenu-gtk3.so.4", libraries)

    def test_dingtalk_preserves_bundled_ssl11_abi_and_warning(self):
        library_root = self.dingtalk / "lib"
        for name in ["libssl.so.1.1", "libcrypto.so.1.1"]:
            library = library_root / name
            self.assertTrue(elf(library), name)
            self.assertIn(name, readelf(library))
            self.assertIn(b"OpenSSL 1.1.1g", library.read_bytes(), name)
        for name in ["dingtalk_dll.so", "doctor"]:
            path = library_root / name
            self.assertTrue(elf(path), name)
            needed = set(re.findall(r"Shared library: \[([^]]+)\]", readelf(path)))
            self.assertTrue(
                {"libssl.so.1.1", "libcrypto.so.1.1"} <= needed, f"{name}: {needed}"
            )
            if name == "doctor":
                self.assertNotIn("libgtk-x11-2.0.so.0", needed)
        warnings = json.loads(os.environ["DINGTALK_KNOWN_VULNERABILITIES"])
        self.assertTrue(
            any("OpenSSL 1.1" in warning and "EOL" in warning for warning in warnings)
        )
        REPORT["dingtalkSsl"] = (
            "Bundled OpenSSL 1.1.1g ABI retained and known vulnerability explicitly recorded; no claim of remediation."
        )

    def test_dingtalk_xcb_fcitx_and_screenshare_wrapper_preserved(self):
        wrapper = self.dingtalk / "bin/dingtalk"
        self.assertTrue(wrapper.is_file())
        text = subprocess.run(
            ["strings", str(wrapper)], capture_output=True, text=True, check=True
        ).stdout
        self.assertIn("QT_QPA_PLATFORM", text)
        self.assertIn("xcb", text)
        self.assertRegex(text, r"(?:unset|--unset)[^\n]*WAYLAND_DISPLAY")
        self.assertIn("LD_PRELOAD", text)
        hook = Path(os.environ["DINGTALK_SCREENSHARE"])
        self.assertTrue(elf(hook))
        self.assertIn(str(hook), text)
        scripts = []
        for path in (self.dingtalk / "bin").iterdir():
            if path.is_file() and path.read_bytes()[:2] == b"#!":
                content = path.read_text()
                scripts.append(content)
                process = subprocess.run(
                    [os.environ["CLIENT_BASH"], "-n", "--", str(path)],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(process.returncode, 0, process.stderr)
        self.assertTrue(
            any(
                "XMODIFIERS" in text
                and "QT_IM_MODULE=fcitx" in text
                and "GTK_IM_MODULE=fcitx" in text
                for text in scripts
            )
        )
        REPORT["dingtalkWrapper"] = (
            "xcb, WAYLAND_DISPLAY removal, Fcitx detection, and same-package screenshare hook statically verified; client not launched."
        )


if __name__ == "__main__":
    try:
        unittest.main(verbosity=2)
    finally:
        if os.environ.get("CLIENT_CHECK_REPORT"):
            Path(os.environ["CLIENT_CHECK_REPORT"]).write_text(
                json.dumps(REPORT, indent=2) + "\n"
            )
