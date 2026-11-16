# Enabled units from `systemctl list-unit-files --state=enabled` on 2026-11-16.
# clash-verge-service, EasyMonitor, and the pamac timers have no NixOS equivalent
# and are listed in inventory/unmapped.md.
{ ... }:
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
}
