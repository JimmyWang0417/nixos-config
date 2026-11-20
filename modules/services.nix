# Enabled units from `systemctl list-unit-files --state=enabled` on 2026-11-16.
# EasyMonitor and the pamac timers have no NixOS equivalent and stay in
# inventory/unmapped.md.
{ config, ... }:
{
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
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
