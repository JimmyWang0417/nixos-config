{ pkgs }:
let
  inherit (pkgs) lib;
  # Lima's upstream getFirmware searches ../share/qemu relative to the QEMU
  # executable returned by LookPath. Keep this layout without /usr symlinks.
  qemu = pkgs.runCommand "claude-cage-qemu-runtime" { } ''
    mkdir -p "$out/bin" "$out/share/qemu"
    ln -s ${pkgs.qemu}/bin/qemu-system-x86_64 "$out/bin/qemu-system-x86_64"
    ln -s ${pkgs.qemu}/bin/qemu-img "$out/bin/qemu-img"
    ln -s ${pkgs.OVMF.fd}/FV/OVMF_CODE.fd "$out/share/qemu/edk2-x86_64-code.fd"
  '';
  tools = [
    qemu
    pkgs.openssh
    pkgs.iproute2
    pkgs.git
    pkgs.glib
    pkgs.systemd
    pkgs.xdg-utils
    pkgs.libnotify
    pkgs.zenity
    pkgs.bash
    pkgs.coreutils
  ];
in
{
  inherit qemu tools;
  path = lib.makeBinPath tools;
}
