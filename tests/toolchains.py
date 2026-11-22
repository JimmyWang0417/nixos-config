#!/usr/bin/env python3
"""Exercise the evaluated activation scripts without network or real HOME writes."""
import json
import os
import pathlib
import shlex
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
STUB = '''#!{python}
import json,os,pathlib,sys
entry=[pathlib.Path(sys.argv[0]).name,*sys.argv[1:]]
with open(os.environ["CALL_LOG"],"a") as f:f.write(json.dumps(entry)+"\\n")
if " ".join(entry)==os.environ.get("FAIL_COMMAND"):sys.exit(42)
'''


class ToolchainActivationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        result = subprocess.run(
            ["nix", "eval", "--impure", "--json", "--no-update-lock-file", "--file", "tests/toolchains.nix"],
            cwd=ROOT, capture_output=True, text=True)
        if result.returncode:
            raise AssertionError(result.stderr)
        cls.policy = json.loads(result.stdout)

    def execute(self, manager, *, fail="", dry_run=False):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            log = root / "calls.jsonl"
            script = self.policy[f"{manager}Activation"]
            script = script.replace(self.policy["homeDirectory"], str(root / "home"))
            for program, name in [("elanProgram", "elan"), ("rustupProgram", "rustup")]:
                stub = root / name
                stub.write_text(STUB.format(python=sys.executable))
                stub.chmod(0o700)
                script = script.replace(self.policy[program], shlex.quote(str(stub)))
            run = 'run() { :; }' if dry_run else 'run() { "$@"; }'
            result = subprocess.run(["bash", "-euc", run + "\n" + script],
                                    env=os.environ | {"CALL_LOG": str(log), "FAIL_COMMAND": fail},
                                    capture_output=True, text=True)
            calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
            return result, calls

    def test_elan_download_precedes_default_selection(self):
        result, calls = self.execute("elan")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [["elan", "toolchain", "install", "stable"], ["elan", "default", "stable"]])

    def test_elan_failed_download_does_not_select_default(self):
        result, calls = self.execute("elan", fail="elan toolchain install stable")
        self.assertEqual(result.returncode, 42)
        self.assertEqual(calls, [["elan", "toolchain", "install", "stable"]])

    def test_rust_stable_download_and_required_components(self):
        result, calls = self.execute("rust")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[:2], [["rustup", "set", "profile", "default"], ["rustup", "default", "stable"]])
        self.assertEqual(calls[2], ["rustup", "component", "add", "--toolchain", "stable", "rustfmt", "clippy", "rust-src"])

    def test_rust_failed_install_does_not_claim_components_ready(self):
        result, calls = self.execute("rust", fail="rustup default stable")
        self.assertEqual(result.returncode, 42)
        self.assertEqual(len(calls), 2)

    def test_dry_run_executes_neither_manager(self):
        for manager in ["elan", "rust"]:
            result, calls = self.execute(manager, dry_run=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
