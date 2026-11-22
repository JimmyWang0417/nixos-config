#!/usr/bin/env bash
# 已装好的 NixOS、flake 还没开时用。不分区，不安装系统。
# flake 能用之后仍是 nixos-rebuild switch --flake <仓库>#orion。
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
force=0
orion_disk_uuid="fd32207f-8a11-48d7-9d04-9316cdb8c265"

case "${1:-}" in
"") ;;
--force) force=1 ;;
*)
  echo "只接受 --force。" >&2
  exit 1
  ;;
esac
if [[ "$#" -gt 1 ]]; then
  echo "只接受 --force。" >&2
  exit 1
fi

# 克隆仓库的是普通用户。root 会把仓库里的文件变成 root 所有。
if [[ "$(id -u)" -eq 0 ]]; then
  echo "请不要用 root 运行。sudo 只用于写入 /etc/nix/nix.conf 和 nixos-rebuild。" >&2
  exit 1
fi

if ! command -v nixos-rebuild >/dev/null 2>&1; then
  echo "这个脚本只给已经装好的 NixOS 用，不负责分区和安装。本机没有 nixos-rebuild。" >&2
  exit 1
fi

# 未注释的 experimental-features / extra-experimental-features 里是否已有这两项。
conf_has_flakes() {
  local text="$1" line value token
  local has_nix_command=0 has_flakes=0
  local -a tokens=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" =~ ^(extra-)?experimental-features[[:space:]]*=[[:space:]]*(.*)$ ]] || continue
    value="${BASH_REMATCH[2]%%#*}"
    read -r -a tokens <<<"$value"
    for token in "${tokens[@]}"; do
      token="${token#\"}"
      token="${token%\"}"
      [[ "$token" == "nix-command" ]] && has_nix_command=1
      [[ "$token" == "flakes" ]] && has_flakes=1
    done
  done <<<"$text"
  [[ "$has_nix_command" -eq 1 && "$has_flakes" -eq 1 ]]
}

# 本次 nix 调用带上实验特性，即使 nix.conf 还是安装器默认值。
if ! conf_has_flakes "${NIX_CONFIG:-}"; then
  if [[ -n "${NIX_CONFIG:-}" ]]; then
    NIX_CONFIG="${NIX_CONFIG}"$'\n'"extra-experimental-features = nix-command flakes"
  else
    NIX_CONFIG="experimental-features = nix-command flakes"
  fi
fi
export NIX_CONFIG

# 二进制缓存：中科大、清华、官方。代理还没起来时也用这一份。
# extra-trusted-public-keys 只追加官方公钥，不替换 Nix 已经信任的钥匙。
# 与 flake.nix 的 nixConfig、modules/core/nix-settings.nix 保持同一份列表。
mirror_substituters="https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org/"
mirror_key="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

nix_config_add() {
  local line="$1"
  case "${NIX_CONFIG:-}" in
  *"$line"*) return ;;
  esac
  if [[ -n "${NIX_CONFIG:-}" ]]; then
    NIX_CONFIG="${NIX_CONFIG}"$'\n'"${line}"
  else
    NIX_CONFIG="${line}"
  fi
}

nix_config_add "substituters = ${mirror_substituters}"
nix_config_add "extra-trusted-public-keys = ${mirror_key}"
nix_config_add "accept-flake-config = true"
export NIX_CONFIG

# 追加到 nix.conf，不覆盖其余行。extra- 不会盖掉已有的 experimental-features。
nix_conf="/etc/nix/nix.conf"
nix_conf_text=""
if [[ -r "$nix_conf" ]]; then
  nix_conf_text="$(<"$nix_conf")"
elif sudo test -f "$nix_conf"; then
  nix_conf_text="$(sudo cat "$nix_conf")"
fi
if ! conf_has_flakes "$nix_conf_text"; then
  sudo mkdir -p /etc/nix
  if [[ -n "$nix_conf_text" ]]; then
    printf '\nextra-experimental-features = nix-command flakes\n' | sudo tee -a "$nix_conf" >/dev/null
  else
    printf 'extra-experimental-features = nix-command flakes\n' | sudo tee -a "$nix_conf" >/dev/null
  fi
fi

# 运行中的 nix-daemon 要等重启才读新的 nix.conf。本次 nixos-rebuild 另外用
# --option 和 NIX_CONFIG 带上同一份 substituters。
if [[ "$nix_conf_text" != *"mirrors.ustc.edu.cn/nix-channels/store"* ]]; then
  sudo mkdir -p /etc/nix
  printf '\nsubstituters = %s\nextra-trusted-public-keys = %s\n' \
    "$mirror_substituters" "$mirror_key" | sudo tee -a "$nix_conf" >/dev/null
fi

# 当前硬件文件是主机 orion 时，不用安装器生成的文件覆盖它。
if [[ -f /etc/nixos/hardware-configuration.nix ]] &&
  grep -F -q "$orion_disk_uuid" "${repo}/hosts/orion/hardware-configuration.nix"; then
  echo "当前硬件文件是主机 orion（Orion-Laptop）的，本脚本不会覆盖。再加一台机器是新的主机文件，不要把生成的 hardware-configuration.nix 拷进 hosts/orion。"
fi

# 路径含空格等字符时用 path: 百分号编码。属性名仍是 orion。
orion_flake_ref() {
  local path="$1"
  if [[ "$path" =~ ^[A-Za-z0-9._+/-]+$ ]]; then
    printf '%s#orion' "$path"
    return
  fi
  local LC_ALL=C encoded="" i c hex
  for ((i = 0; i < ${#path}; i++)); do
    c="${path:i:1}"
    case "$c" in
    [A-Za-z0-9._~/-]) encoded+="$c" ;;
    *)
      printf -v hex '%%%02X' "'$c"
      encoded+="$hex"
      ;;
    esac
  done
  printf 'path:%s#orion' "$encoded"
}

flake_ref="$(orion_flake_ref "$repo")"

cd "$repo"
rebuild=(
  sudo
  "NIX_CONFIG=${NIX_CONFIG}"
  nixos-rebuild
  switch
  --flake "$flake_ref"
  --accept-flake-config
  --option
  substituters
  "$mirror_substituters"
  --option
  extra-trusted-public-keys
  "$mirror_key"
  --extra-experimental-features
  "nix-command flakes"
)

hostname_now=""
if [[ -r /etc/hostname ]]; then
  hostname_now="$(tr -d '[:space:]' </etc/hostname)"
fi

# 不是 Orion 且没有 --force：flakes 已经写好，不切换。
if [[ "$hostname_now" != "Orion-Laptop" && "$force" -ne 1 ]]; then
  echo "当前主机名不是 Orion-Laptop，已启用 flakes，未切换。要执行的命令："
  quoted="$(printf '%q ' "${rebuild[@]}")"
  printf '%s\n' "${quoted% }"
  exit 0
fi

"${rebuild[@]}"
