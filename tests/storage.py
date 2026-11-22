#!/usr/bin/env python3
"""Validate adaptive storage policy without GC, service activation or /run writes."""

import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "adaptive_gc", ROOT / "modules/core/nix-storage/adaptive-gc.py"
)
ADAPTIVE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ADAPTIVE)
GIB = 1024**3


class AdaptiveStorageTests(unittest.TestCase):
    def write(self, store, output):
        with contextlib.redirect_stdout(io.StringIO()):
            ADAPTIVE.write_config(store, output)

    def test_tiny_disks_do_not_reserve_fixed_gigabytes(self):
        self.assertEqual(ADAPTIVE.thresholds(8 * GIB), (8 * GIB // 10, 8 * GIB // 5))

    def test_normal_disks_follow_capacity_percentages(self):
        self.assertEqual(ADAPTIVE.thresholds(100 * GIB), (5 * GIB, 10 * GIB))

    def test_large_disks_obey_reservation_caps(self):
        self.assertEqual(ADAPTIVE.thresholds(4 * 1024 * GIB), (16 * GIB, 32 * GIB))

    def test_watermarks_are_positive_ordered_and_monotone(self):
        capacities = sorted(
            {100, 101, 999} | {2**exponent for exponent in range(10, 64)}
        )
        previous = (0, 0)
        for capacity in capacities:
            with self.subTest(capacity=capacity):
                low, high = ADAPTIVE.thresholds(capacity)
                self.assertTrue(0 < low < high < capacity)
                self.assertLessEqual(low, 16 * GIB)
                self.assertLessEqual(high, 32 * GIB)
                self.assertGreaterEqual(low, previous[0])
                self.assertGreaterEqual(high, previous[1])
                previous = low, high
        for invalid in [-1, 0, 99]:
            with self.assertRaises(ValueError):
                ADAPTIVE.thresholds(invalid)

    def test_writer_uses_actual_store_filesystem_and_replaces_atomically(self):
        with tempfile.TemporaryDirectory() as directory:
            store = Path(directory) / "store"
            store.mkdir()
            output = Path(directory) / "settings.conf"
            output.write_text("previous configuration\n")
            with output.open() as old_file:
                self.write(store, output)
                self.assertEqual(old_file.read(), "previous configuration\n")
            stats = os.statvfs(store)
            low, high = ADAPTIVE.thresholds(stats.f_blocks * stats.f_frsize)
            self.assertIn(f"min-free = {low}\nmax-free = {high}\n", output.read_text())
            self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o644)
            self.assertEqual(
                sorted(p.name for p in Path(directory).iterdir()),
                ["settings.conf", "store"],
            )

    def test_failed_replacement_preserves_old_config_and_cleans_temporary_file(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "settings.conf"
            output.write_text("old\n")
            with mock.patch.object(
                ADAPTIVE.os, "replace", side_effect=OSError("simulated failure")
            ):
                with self.assertRaisesRegex(OSError, "simulated failure"):
                    self.write(directory, output)
            self.assertEqual(output.read_text(), "old\n")
            self.assertEqual(
                [p.name for p in Path(directory).iterdir()], ["settings.conf"]
            )

    def test_capacity_change_is_recalculated_on_next_writer_run(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "settings.conf"
            for gib in [100, 200]:
                stats = mock.Mock(f_blocks=gib * GIB // 4096, f_frsize=4096)
                with mock.patch.object(ADAPTIVE.os, "statvfs", return_value=stats):
                    self.write(directory, output)
                low, high = ADAPTIVE.thresholds(gib * GIB)
                self.assertIn(
                    f"min-free = {low}\nmax-free = {high}\n", output.read_text()
                )

    def test_unreadable_store_fails_without_publishing_config(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "settings.conf"
            with self.assertRaises(FileNotFoundError):
                self.write(Path(directory) / "missing", output)
            self.assertFalse(output.exists())

    def test_generated_optional_include_is_accepted_by_native_nix(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "nix.conf"
            generated = Path(directory) / "settings.conf"
            self.write(directory, generated)
            config.write_text(f"!include {generated}\n")
            result = subprocess.run(
                [
                    "nix",
                    "--extra-experimental-features",
                    "nix-command",
                    "config",
                    "show",
                    "--json",
                ],
                env=os.environ | {"NIX_USER_CONF_FILES": str(config)},
                capture_output=True,
                text=True,
                cwd=ROOT,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            parsed = json.loads(result.stdout)
            stats = os.statvfs(directory)
            low, high = ADAPTIVE.thresholds(stats.f_blocks * stats.f_frsize)
            self.assertEqual(parsed["min-free"]["value"], low)
            self.assertEqual(parsed["max-free"]["value"], high)

    def test_missing_optional_include_does_not_break_native_nix(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "nix.conf"
            config.write_text(f"!include {directory}/not-yet-generated.conf\n")
            result = subprocess.run(
                [
                    "nix",
                    "--extra-experimental-features",
                    "nix-command",
                    "config",
                    "show",
                    "--json",
                ],
                env=os.environ | {"NIX_USER_CONF_FILES": str(config)},
                capture_output=True,
                text=True,
                cwd=ROOT,
            )
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_evaluated_system_wiring(self):
        result = subprocess.run(
            [
                "nix",
                "eval",
                "--impure",
                "--json",
                "--no-update-lock-file",
                "--file",
                "tests/storage.nix",
            ],
            capture_output=True,
            text=True,
            cwd=ROOT,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        policy = json.loads(result.stdout)
        self.assertEqual(len(policy["checks"]), 10)
        self.assertTrue(all(policy["checks"].values()))


if __name__ == "__main__":
    unittest.main(verbosity=2)
