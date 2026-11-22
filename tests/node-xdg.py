"""Verify opaque state migration and shell integration without touching real HOME."""

import errno
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT / "home/modules/development/node"
spec = importlib.util.spec_from_file_location("node_migrate", DIRECTORY / "migrate.py")
migration = importlib.util.module_from_spec(spec)
spec.loader.exec_module(migration)


class NodeXdgTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="node 状态 ")
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.roots = [
            self.home,
            self.home / ".config",
            self.home / ".cache",
            self.home / ".local/share",
            self.home / ".local/state",
        ]

    def run_migration(self, dry_run=False):
        return migration.migrate(*self.roots, dry_run=dry_run)

    def test_moves_opaque_files_and_relative_bin_symlinks_intact(self):
        (self.home / ".npm").mkdir()
        (self.home / ".npm/cache-entry").write_bytes(b"cache data")
        prefix = self.home / ".npm-global"
        (prefix / "bin").mkdir(parents=True)
        (prefix / "lib/node_modules/example").mkdir(parents=True)
        (prefix / "lib/node_modules/example/cli.js").write_text("// test CLI\n")
        (prefix / "bin/example").symlink_to("../lib/node_modules/example/cli.js")
        credentials = b"//example.invalid/:_authToken=synthetic-test-value\nprefix=~/.npm-global\n"
        config = self.home / ".npmrc"
        config.write_bytes(credentials)
        config.chmod(0o600)
        (self.home / ".node_repl_history").write_bytes(b"1 + 1\n")
        result = self.run_migration()
        self.assertTrue(all(row["status"] == "moved" for row in result))
        target = self.roots[1] / "npm/npmrc"
        self.assertEqual(target.read_bytes(), credentials)
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)
        self.assertEqual(
            (self.roots[3] / "npm/bin/example").read_text(), "// test CLI\n"
        )
        self.assertEqual(
            os.readlink(self.roots[3] / "npm/bin/example"),
            "../lib/node_modules/example/cli.js",
        )
        self.assertFalse(
            any(
                (self.home / name).exists()
                for name in [".npm", ".npm-global", ".npmrc", ".node_repl_history"]
            )
        )
        self.assertNotIn("synthetic-test-value", json.dumps(result))

    def test_dry_run_creates_no_directories_or_lock(self):
        before = list(self.home.iterdir())
        self.run_migration(dry_run=True)
        self.assertEqual(list(self.home.iterdir()), before)

    def test_existing_destination_preserves_both_sides(self):
        (self.home / ".npmrc").write_bytes(b"legacy opaque config")
        target = self.roots[1] / "npm/npmrc"
        target.parent.mkdir(parents=True)
        target.write_bytes(b"new opaque config")
        result = self.run_migration()
        self.assertEqual(result[2]["status"], "preserved-conflict")
        self.assertEqual((self.home / ".npmrc").read_bytes(), b"legacy opaque config")
        self.assertEqual(target.read_bytes(), b"new opaque config")

    def test_symlink_sources_and_destination_ancestors_are_not_followed(self):
        external = self.home / "untouched"
        external.mkdir()
        (self.home / ".npm").symlink_to(external)
        self.roots[1].symlink_to(external)
        result = self.run_migration()
        self.assertEqual(result[0]["status"], "preserved-symlink")
        self.assertEqual(result[2]["status"], "preserved-symlink")
        self.assertEqual(list(external.iterdir()), [])

    def test_cross_filesystem_move_does_not_copy_or_delete_source(self):
        (self.home / ".npm").mkdir()
        with mock.patch.object(
            migration,
            "rename_noreplace",
            side_effect=OSError(errno.EXDEV, "different filesystem"),
        ):
            result = self.run_migration()
        self.assertEqual(result[0]["status"], "preserved-cross-filesystem")
        self.assertTrue((self.home / ".npm").is_dir())
        self.assertFalse((self.roots[2] / "npm").exists())

    def test_atomic_rename_refuses_a_racing_destination(self):
        source = self.home / ".npmrc"
        source.write_bytes(b"original")
        target = self.roots[1] / "npm/npmrc"
        real_rename = migration.rename_noreplace

        def racing_rename(old, new):
            new.write_bytes(b"concurrent writer")
            return real_rename(old, new)

        with mock.patch.object(
            migration, "rename_noreplace", side_effect=racing_rename
        ):
            result = self.run_migration()
        self.assertEqual(result[2]["status"], "preserved-conflict")
        self.assertEqual(source.read_bytes(), b"original")
        self.assertEqual(target.read_bytes(), b"concurrent writer")

    def test_running_old_prefix_process_defers_every_move(self):
        with mock.patch.object(migration, "active_references", return_value=[12345]):
            result = self.run_migration()
        self.assertEqual(
            result, [{"status": "preserved-active-process", "processIds": [12345]}]
        )
        self.assertEqual(list(self.home.iterdir()), [])

    def test_second_run_is_idempotent(self):
        self.run_migration()
        result = self.run_migration()
        self.assertTrue(all(row["status"] == "present" for row in result))

    def test_shell_environment_appends_global_bin_after_nix_paths(self):
        env = os.environ.copy()
        for key in [
            "NPM_CONFIG_USERCONFIG",
            "NPM_CONFIG_CACHE",
            "NPM_CONFIG_PREFIX",
            "NODE_REPL_HISTORY",
        ]:
            env.pop(key, None)
        env.update(
            dict(
                zip(
                    [
                        "XDG_CONFIG_HOME",
                        "XDG_CACHE_HOME",
                        "XDG_DATA_HOME",
                        "XDG_STATE_HOME",
                    ],
                    map(str, self.roots[1:]),
                )
            )
        )
        new_bin = str(self.roots[3] / "npm/bin")
        old_bin = str(Path.home() / ".npm-global/bin")
        env["PATH"] = (
            old_bin + ":" + new_bin + ":/nix/profile/bin:" + os.environ["PATH"]
        )
        script = '. "$1"; "$2" -c \'import json,os; print(json.dumps({k:os.environ[k] for k in ["HOME","PATH","NPM_CONFIG_PREFIX","NPM_CONFIG_USERCONFIG","NODE_REPL_HISTORY"]}))\''
        result = subprocess.run(
            ["bash", "-c", script, "--", str(DIRECTORY / "env.sh"), sys.executable],
            env=env,
            capture_output=True,
            text=True,
            check=True,
        )
        observed = json.loads(result.stdout)
        self.assertEqual(observed["HOME"], os.environ["HOME"])
        self.assertEqual(observed["PATH"].split(":")[-1], new_bin)
        self.assertNotIn(old_bin, observed["PATH"].split(":"))
        self.assertLess(
            observed["PATH"].split(":").index("/nix/profile/bin"),
            observed["PATH"].split(":").index(new_bin),
        )
        self.assertEqual(
            observed["NPM_CONFIG_USERCONFIG"], str(self.roots[1] / "npm/npmrc")
        )

    @unittest.skipUnless(shutil.which("npm"), "npm is not installed")
    def test_npm_prefix_environment_keeps_local_and_explicit_project_installs(self):
        self.run_migration()
        fixture = self.home / "local fixture"
        fixture.mkdir()
        (fixture / "package.json").write_text(
            json.dumps({"name": "node-xdg-fixture", "version": "1.0.0"})
        )
        prefix = self.roots[3] / "npm"
        before = list(prefix.iterdir())
        env = os.environ | {
            "NPM_CONFIG_USERCONFIG": str(self.roots[1] / "npm/npmrc"),
            "NPM_CONFIG_CACHE": str(self.roots[2] / "npm"),
            "NPM_CONFIG_PREFIX": str(prefix),
            "NODE_REPL_HISTORY": str(self.roots[4] / "node/repl_history"),
        }
        for name, explicit in [("local 项目", False), ("prefix 项目", True)]:
            project = self.home / name
            project.mkdir()
            (project / "package.json").write_text(
                json.dumps({"private": True, "name": "local-test", "version": "1.0.0"})
            )
            command = ["npm"] + (["--prefix", str(project)] if explicit else [])
            command += [
                "install",
                "--ignore-scripts",
                "--no-audit",
                "--no-fund",
                "--offline",
                str(fixture),
            ]
            result = subprocess.run(
                command,
                cwd=self.home if explicit else project,
                env=env,
                capture_output=True,
                text=True,
                timeout=20,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((project / "node_modules/node-xdg-fixture").is_dir())
            self.assertTrue((project / "package-lock.json").is_file())
        self.assertEqual(list(prefix.iterdir()), before)


if __name__ == "__main__":
    unittest.main(verbosity=2)
