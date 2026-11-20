# Enabled units from `systemctl list-unit-files --state=enabled` on 2026-11-16.
# EasyMonitor and the pamac timers have no NixOS equivalent and stay in
# inventory/unmapped.md.
{ config, pkgs, ... }:
let
  # Small text file. remote-add reads it from the store, then still has to
  # reach Flathub for the summary. The oneshot retries; it does not sit in
  # front of SDDM.
  flathubRepo = pkgs.fetchurl {
    url = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    hash = "sha256-M3HdJQ5h2eFjNjAHP+/aFTzUQm9y9K+gwzc64uj+oDo=";
  };
in
{
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # Skanlite is installed. Logged-in seats get the scanner through uaccess;
  # jimmywang0417 is also in the scanner group.
  hardware.sane.enable = true;

  # GTK and Electron move-to-trash. Dolphin keeps using KIO.
  services.gvfs.enable = true;

  # The OpenRGB window is the client. The upstream unit stays off, the same
  # as the machine. These rules are what let that window open the devices.
  services.udev.packages = [ pkgs.openrgb ];
  boot.kernelModules = [
    "i2c-dev"
    "i2c-i801"
  ];

  # ToDesk remote control. The GUI still signs in and shows the device code.
  # plasmax11 stays the default session so the controlled desktop is X11.
  services.todesk.enable = true;

  # Flathub is the system remote on this laptop. No Flatpak apps are installed.
  services.flatpak.enable = true;
  systemd.services.flatpak-flathub = {
    description = "Register the Flathub system remote";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 600;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 20;
      Restart = "on-failure";
      RestartSec = 60;
    };
    script = ''
      if ${pkgs.flatpak}/bin/flatpak remote-list --system --columns=name | ${pkgs.gnugrep}/bin/grep -qx flathub; then
        exit 0
      fi
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub ${flathubRepo}
    '';
  };

  # Run AppImages that are not Nix packages. animeko stays uninstalled.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  services.cron.enable = true;
  virtualisation.docker.enable = true;

  services.fwupd.enable = true;
  services.fstrim.enable = true;
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
  services.hardware.bolt.enable = true;
  networking.modemmanager.enable = true;

  services.logrotate.enable = true;

  # nixos-26.05 programs.clash-verge. The GUI cannot create the virtual NIC.
  # serviceMode starts clash-verge-service as root. The unit name is
  # clash-verge.service. The socket is mode 0660 and uses this group.
  # jimmywang0417's primary group is not users.
  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    group = config.users.users.jimmywang0417.group;
  };
}
