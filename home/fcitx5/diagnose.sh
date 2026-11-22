#!/usr/bin/env bash
# Read session state only; this does not restart Fcitx or change its settings.
set -u

for name in XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY WAYLAND_DISPLAY XMODIFIERS GTK_IM_MODULE QT_IM_MODULE QT_IM_MODULES QT_PLUGIN_PATH SDL_IM_MODULE NIXOS_OZONE_WL; do
  printf '%s=%s\n' "$name" "${!name-<unset>}"
done

printf '\nFcitx processes for this user:\n'
pgrep -a -u "$(id -u)" fcitx5 || true

if command -v fcitx5-remote >/dev/null 2>&1; then
  printf '\nInput method state (0=unavailable, 1=inactive, 2=active):\n'
  fcitx5-remote || true
  printf 'Selected input method: '
  fcitx5-remote -n || true
else
  printf '\nfcitx5-remote is not installed in this running session.\n'
fi

printf '\nFor the full upstream report, run fcitx5-diagnose in this desktop session.\n'
