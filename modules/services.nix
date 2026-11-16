{ config, lib, ... }:
let
  cfg = config.orion.services;
in
{
  options.orion.services = {
    enable = lib.mkEnableOption "laptop service profile";
    docker.enable = lib.mkEnableOption "Docker engine";
    printing.enable = lib.mkEnableOption "CUPS";
    bluetooth.enable = lib.mkEnableOption "Bluetooth";
    modemmanager.enable = lib.mkEnableOption "ModemManager";
    bolt.enable = lib.mkEnableOption "Thunderbolt boltd";
    cron.enable = lib.mkEnableOption "cron";
    fstrim.enable = lib.mkEnableOption "fstrim timer";
    fwupd.enable = lib.mkEnableOption "fwupd";
    pipewire.enable = lib.mkEnableOption "PipeWire";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.docker.enable {
      virtualisation.docker.enable = true;
    })
    (lib.mkIf cfg.printing.enable {
      services.printing.enable = true;
    })
    (lib.mkIf cfg.bluetooth.enable {
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;
    })
    (lib.mkIf cfg.modemmanager.enable {
      networking.modemmanager.enable = true;
    })
    (lib.mkIf cfg.bolt.enable {
      services.hardware.bolt.enable = true;
    })
    (lib.mkIf cfg.cron.enable {
      services.cron.enable = true;
    })
    (lib.mkIf cfg.fstrim.enable {
      services.fstrim.enable = true;
    })
    (lib.mkIf cfg.fwupd.enable {
      services.fwupd.enable = true;
    })
    (lib.mkIf cfg.pipewire.enable {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    })
  ];
}
