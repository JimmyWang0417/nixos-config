{ config, pkgs, ... }:
with pkgs; [
  dmidecode
  usbutils
  pciutils
  powertop
  acpi
  config.boot.kernelPackages.cpupower
  inxi
  openrgb
]
