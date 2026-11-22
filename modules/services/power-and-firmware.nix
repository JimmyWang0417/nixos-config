{ ... }: {
  services.fwupd.enable = true;
  services.fstrim.enable = true;
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
  services.hardware.bolt.enable = true;
  networking.modemmanager.enable = true;

}
