#!/usr/bin/env bash
# Evaluate nixosConfigurations.orion and check the inventory.
# Does not run nixos-rebuild and does not touch disks or the bootloader.
set -euo pipefail
cd "$(dirname "$0")/.."

export PATH="${HOME}/.local/bin:${PATH}"
export NIX_CONFIG="${NIX_CONFIG:-sandbox = false
experimental-features = nix-command flakes
substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org/
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
connect-timeout = 10
fallback = true}"

echo "=== leak check: filesystem UUID and hostname assignment stay in hosts/ ==="
if rg -n "fd32207f-8a11-48d7-9d04-9316cdb8c265|0AF1-1155" modules home flake.nix; then
  echo "FAIL: disk UUID leaked out of hosts/"
  exit 1
fi
if rg -n 'networking\.hostName[[:space:]]*=' modules home; then
  echo "FAIL: networking.hostName is assigned outside hosts/"
  exit 1
fi
echo "leak check ok"

echo "=== inventory files ==="
python3 - <<'PY'
import pathlib, re, subprocess, sys
root = pathlib.Path(".")
functions = (root / "inventory/functions.md").read_text()
unmapped = (root / "inventory/unmapped.md").read_text()
missing_paths = []
for line in functions.splitlines():
    if not line.startswith("|"):
        continue
    cols = [c.strip().strip("`") for c in line.strip().strip("|").split("|")]
    if len(cols) < 2 or cols[0] in {"功能", "---"} or set(cols[0]) <= {"-", " "}:
        continue
    provider = cols[-1].split()[0]
    if provider.startswith(("hosts/", "modules/", "home/", "inventory/")):
        path = provider.split(":")[0]
        if not (root / path).exists():
            missing_paths.append(provider)
if missing_paths:
    print("FAIL: functions.md points at missing files:")
    print("\n".join(missing_paths))
    sys.exit(1)
bad_rows = []
for line in unmapped.splitlines():
    if not line.startswith("|"):
        continue
    cols = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cols) < 2 or cols[0] in {"名称", "---"} or set(cols[0]) <= {"-", " "}:
        continue
    if cols[-1] == "":
        bad_rows.append(line)
if bad_rows:
    print("FAIL: unmapped rows without a reason")
    sys.exit(1)
blob = functions + "\n" + unmapped
for key in ["fcitx", "plasmax11", "docker", "btrfs", "nvidia", "pipewire", "bluetooth", "NetworkManager", "Tela", "WhiteSur", "sddm"]:
    if key not in blob:
        print(f"FAIL: {key} is neither documented nor unmapped")
        sys.exit(1)
names = subprocess.check_output(["pacman", "-Qe"], text=True)
missing = []
for line in names.splitlines():
    name = line.split()[0]
    if not re.search(r"(?<![A-Za-z0-9_.+-])" + re.escape(name) + r"(?![A-Za-z0-9_.+-])", blob):
        missing.append(name)
if missing:
    print("FAIL: pacman -Qe entries missing from functions.md and unmapped.md:")
    print("\n".join(missing))
    sys.exit(1)
print(f"inventory ok, {len(names.splitlines())} explicit packages accounted for")
PY

echo "=== nix eval nixosConfigurations.orion ==="
host=$(nix eval --raw .#nixosConfigurations.orion.config.networking.hostName)
session=$(nix eval --raw .#nixosConfigurations.orion.config.services.displayManager.defaultSession)
rootdev=$(nix eval --raw .#nixosConfigurations.orion.config.fileSystems.\"/\".device)
echo "networking.hostName=${host}"
echo "defaultSession=${session}"
echo "fileSystems./.device=${rootdev}"
test "$host" = "Orion-Laptop"
test "$session" = "plasmax11"
test "$rootdev" = "/dev/disk/by-uuid/fd32207f-8a11-48d7-9d04-9316cdb8c265"
echo "=== home-manager plasma activation ==="
nix eval .#nixosConfigurations.orion.config.home-manager.users.jimmywang0417.home.activation --apply 'builtins.attrNames'
echo "=== toplevel drv ==="
nix eval --raw .#nixosConfigurations.orion.config.system.build.toplevel.drvPath
echo
echo "=== nix flake check ==="
nix flake check
echo "eval.sh ok"
