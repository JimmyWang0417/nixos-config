{ ... }: {
  imports = [
    ./printing.nix
    ./desktop-files.nix
    ./device-access.nix
    ./remote-desktop.nix
    ./flatpak.nix
    ./appimage.nix
    ./scheduling.nix
    ./docker.nix
    ./power-and-firmware.nix
    ./clash-verge.nix
  ];
}
