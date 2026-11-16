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

echo "== nix flake check =="
if nix flake check --help 2>&1 | grep -q -- '--no-build'; then
  nix flake check --no-build --no-update-lock-file --show-trace
else
  nix flake check --no-update-lock-file --show-trace
fi

echo "== nixosConfigurations.orion toplevel drv =="
nix eval --raw --no-update-lock-file --show-trace .#nixosConfigurations.orion.config.system.build.toplevel.drvPath
echo
