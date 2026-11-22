#!/usr/bin/env bash
# Evaluate nixosConfigurations.orion. A non-zero status means the flake did not evaluate.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v nix >/dev/null 2>&1; then
  echo "nix is not on PATH" >&2
  exit 127
fi

echo "== nix --version =="
nix --version

echo "== package sources and migration invariants =="
nix eval --impure --json --no-update-lock-file --show-trace --file tests/package-source.nix
echo

echo "== input method configuration and session behavior =="
python3 tests/input-method.py

echo "== private archive safety =="
python3 tests/test_private_restore.py

echo "== managed stable toolchain activation =="
python3 tests/toolchains.py

echo "== adaptive Nix storage maintenance =="
python3 tests/storage.py

echo "== Node XDG environment =="
nix eval --impure --json --no-update-lock-file --show-trace --file tests/node-xdg.nix
echo

echo "== English XDG directories and Chinese locale =="
nix eval --impure --json --no-update-lock-file --show-trace --file tests/user-directories.nix
echo

echo "== development tools =="
nix eval --impure --json --no-update-lock-file --show-trace --file tests/development.nix
echo

echo "== nix flake check =="
if nix flake check --help 2>&1 | grep -q -- '--no-build'; then
  nix flake check --no-build --no-update-lock-file --show-trace
else
  nix flake check --no-update-lock-file --show-trace
fi

echo "== nixosConfigurations.orion toplevel drv =="
nix eval --raw --no-update-lock-file --show-trace .#nixosConfigurations.orion.config.system.build.toplevel.drvPath
echo
