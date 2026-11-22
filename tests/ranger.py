"""Exercise actual preview/archive/opener programs using temporary user files."""

import json
import os
from pathlib import Path
import subprocess
import struct
import tempfile
import unittest
import zlib

SCOPE = os.environ["RANGER_TEST_SCOPE"]
RIFLE = os.environ["RANGER_TEST_RIFLE"]


class RangerIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="ranger 中文 ")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def run_command(self, *args, cwd=None, env=None):
        return subprocess.run(
            args,
            cwd=cwd or self.root,
            env=env,
            capture_output=True,
            text=True,
            timeout=10,
        )

    def preview(self, path, images="False"):
        return self.run_command(
            "bash",
            SCOPE,
            str(path),
            "80",
            "24",
            str(self.root / "preview cache"),
            images,
        )

    def test_7zz_archive_preview_is_listing_only(self):
        source = self.root / "中文 文档;touch injected.txt"
        source.write_text("archive data\n")
        archive = self.root / "资料 $(touch injected).7z"
        made = self.run_command("7zz", "a", "-t7z", "--", str(archive), str(source))
        self.assertEqual(made.returncode, 0, made.stderr)
        source.unlink()
        preview = self.preview(archive, "True")
        self.assertEqual(preview.returncode, 5, preview.stderr)
        self.assertIn(source.name, preview.stdout)
        self.assertFalse(source.exists())
        self.assertFalse((self.root / "injected").exists())

    def test_atool_uses_official_7zz_to_extract_in_temporary_directory(self):
        source = self.root / "待解压 中文.txt"
        source.write_text("expected content\n")
        archive = self.root / "资料 包.7z"
        self.assertEqual(
            self.run_command(
                "7zz", "a", "-t7z", "--", str(archive), str(source)
            ).returncode,
            0,
        )
        source.unlink()
        actions = self.run_command("rifle", "-c", RIFLE, "-l", "--", str(archive))
        self.assertEqual(actions.returncode, 0, actions.stderr)
        extraction = next(
            line
            for line in actions.stdout.splitlines()
            if "atool --option=path_7z=7zz --extract" in line
        )
        number = extraction.split(":", 1)[0]
        result = self.run_command(
            "rifle", "-c", RIFLE, "-p", number, "--", str(archive)
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        extracted = list(self.root.rglob(source.name))
        self.assertEqual(len(extracted), 1)
        self.assertEqual(extracted[0].read_text(), "expected content\n")

    def test_preview_does_not_execute_shell_or_python(self):
        for suffix, content in [
            ("sh", "touch executed\n"),
            ("py", "open('executed', 'w').write('bad')\n"),
        ]:
            script = self.root / f"脚本 $(touch injected).{suffix}"
            script.write_text(content)
            script.chmod(0o700)
            result = self.preview(script)
            self.assertIn(result.returncode, [2, 5], result.stderr)
            self.assertFalse((self.root / "executed").exists())
            self.assertFalse((self.root / "injected").exists())

    def test_slow_preview_helper_is_stopped_by_deadline(self):
        slow = self.root / "highlight"
        slow.write_text("#!/usr/bin/env bash\nsleep 20\n")
        slow.chmod(0o700)
        source = self.root / "slow.txt"
        source.write_text("small text\n")
        env = os.environ | {"PATH": str(self.root) + os.pathsep + os.environ["PATH"]}
        result = self.run_command(
            "bash",
            SCOPE,
            str(source),
            "80",
            "24",
            str(self.root / "cache"),
            "False",
            env=env,
        )
        self.assertEqual(result.returncode, 124, result.stderr)

    def test_pdf_text_and_image_cache_paths(self):
        # A small deterministic PDF generated locally; no document parser dependency.
        pdf = self.root / "文档 空格.pdf"
        content = b"BT /F1 12 Tf 20 50 Td (Preview text) Tj ET"
        objects = [
            b"<< /Type /Catalog /Pages 2 0 R >>",
            b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 150 100] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
            b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
            b"<< /Length "
            + str(len(content)).encode()
            + b" >>\nstream\n"
            + content
            + b"\nendstream",
        ]
        data = b"%PDF-1.4\n"
        offsets = [0]
        for number, obj in enumerate(objects, 1):
            offsets.append(len(data))
            data += str(number).encode() + b" 0 obj\n" + obj + b"\nendobj\n"
        xref = len(data)
        data += b"xref\n0 6\n0000000000 65535 f \n"
        data += b"".join(f"{offset:010d} 00000 n \n".encode() for offset in offsets[1:])
        data += (
            f"trailer\n<< /Root 1 0 R /Size 6 >>\nstartxref\n{xref}\n%%EOF\n".encode()
        )
        pdf.write_bytes(data)
        text = self.preview(pdf)
        self.assertEqual(text.returncode, 5, text.stderr)
        self.assertIn("Preview text", text.stdout)
        image = self.preview(pdf, "True")
        self.assertEqual(image.returncode, 6, image.stderr)
        self.assertTrue(
            (self.root / "preview cache").read_bytes().startswith(b"\x89PNG")
        )

    def test_rifle_default_editor_preserves_filename_arguments(self):
        executable = self.root / "nvim"
        executable.write_text(
            "#!/usr/bin/env python3\nimport json,os,sys\nopen(os.environ['ARGV_LOG'],'w').write(json.dumps(sys.argv[1:]))\n"
        )
        executable.chmod(0o700)
        source = self.root / "中文 空格;touch injected.txt"
        source.write_text("editable text\n")
        log = self.root / "arguments.json"
        env = os.environ | {
            "PATH": str(self.root) + os.pathsep + os.environ["PATH"],
            "EDITOR": "nvim",
            "VISUAL": "",
            "ARGV_LOG": str(log),
            "DISPLAY": "",
        }
        result = self.run_command("rifle", "-c", RIFLE, "--", str(source), env=env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(log.read_text()), ["--", str(source)])
        self.assertFalse((self.root / "injected.txt").exists())

    def test_sixel_encoder_and_image_preview_dispatch(self):
        image = self.root / "图片 空格.png"

        def chunk(kind, data):
            return (
                struct.pack(">I", len(data))
                + kind
                + data
                + struct.pack(">I", zlib.crc32(kind + data))
            )

        image.write_bytes(
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(b"\x00\xff\x00\x00"))
            + chunk(b"IEND", b"")
        )
        preview = self.preview(image, "True")
        self.assertEqual(preview.returncode, 7, preview.stderr)
        encoded = subprocess.run(
            ["magick", str(image), "sixel:-"], capture_output=True, timeout=10
        )
        self.assertEqual(encoded.returncode, 0, encoded.stderr)
        self.assertIn(b"\x1bP", encoded.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
