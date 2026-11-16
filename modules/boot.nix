{ config, lib, ... }:
let
  cfg = config.orion.boot;
in
{
  options.orion.boot = {
    enable = lib.mkEnableOption "GRUB EFI profile";
    efiSysMountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/boot/efi";
      description = "EFI system partition mount point. Hosts with a different layout override this.";
    };
    canTouchEfiVariables = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether a future nixos-rebuild may write EFI boot variables.";
    };
    timeout = lib.mkOption {
      type = lib.types.int;
      default = 5;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
    boot.loader.efi.efiSysMountPoint = cfg.efiSysMountPoint;
    boot.loader.efi.canTouchEfiVariables = cfg.canTouchEfiVariables;
    boot.loader.timeout = cfg.timeout;
  };
}
