{ config, lib, pkgs, inputs, hostName, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  networking.hostName = "Orion-Laptop";
  system.stateVersion = "26.05";

  boot.kernelPackages = pkgs.linuxPackages_6_12;
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams = [ "mem_sleep_default=deep" ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "thunderbolt"
  ];
  boot.tmp.useTmpfs = true;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.firmware = [ pkgs.sof-firmware ];

  # nvme0 (SK hynix 512G) is Windows: NTFS E88024F38024C9C0 and recovery
  # 24AC6033AC5FFE24 are intentionally not declared. nvme1p1 NTFS
  # CA1CDD311CDD18F1 is not mounted. No swapfile exists, so there is no resume.
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/fd32207f-8a11-48d7-9d04-9316cdb8c265";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd:1" "ssd" "discard=async" "space_cache=v2" ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/fd32207f-8a11-48d7-9d04-9316cdb8c265";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd:1" "ssd" "discard=async" "space_cache=v2" ];
  };
  fileSystems."/var/cache" = {
    device = "/dev/disk/by-uuid/fd32207f-8a11-48d7-9d04-9316cdb8c265";
    fsType = "btrfs";
    options = [ "subvol=@cache" "compress=zstd:1" "ssd" "discard=async" "space_cache=v2" ];
  };
  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/fd32207f-8a11-48d7-9d04-9316cdb8c265";
    fsType = "btrfs";
    options = [ "subvol=@log" "compress=zstd:1" "ssd" "discard=async" "space_cache=v2" ];
  };
  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/0AF1-1155";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };
  swapDevices = [ ];

  orion.boot.enable = true;
  orion.nvidia = {
    enable = true;
    open = true;
    finegrained = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
  orion.desktop = {
    enable = true;
    defaultSession = "plasmax11";
    sddmTheme = "breeze";
    autoLogin.enable = true;
    autoLogin.user = "jimmywang0417";
  };
  orion.chinese.enable = true;
  orion.locale.enable = true;
  orion.users.jimmy.enable = true;
  orion.services = {
    enable = true;
    docker.enable = true;
    printing.enable = true;
    bluetooth.enable = true;
    modemmanager.enable = true;
    bolt.enable = true;
    cron.enable = true;
    fstrim.enable = true;
    fwupd.enable = true;
    pipewire.enable = true;
  };
  orion.packages.enable = true;
  orion.networking.enable = true;
  orion.nix = {
    enable = true;
    allowUnfree = true;
    chinaMirrors.enable = true;
  };
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
  hardware.graphics.extraPackages32 = [ pkgs.pkgsi686Linux.intel-media-driver ];
  orion.secrets.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-bak";
  home-manager.extraSpecialArgs = { inherit inputs hostName; };
  home-manager.users.jimmywang0417 = import ../../home/jimmy.nix;

  assertions = [
    {
      assertion = hostName == config.networking.hostName;
      message = "flake hostName and hosts/orion networking.hostName diverged";
    }
    {
      assertion = config.services.displayManager.defaultSession == "plasmax11";
      message = "Orion default session must stay plasmax11";
    }
  ];
}
