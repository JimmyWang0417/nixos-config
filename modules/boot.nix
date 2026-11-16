{ config, lib, ... }:
let
  cfg = config.orion.boot;
  # Files stay on the machine. A string, so evaluation does not copy them
  # into the Nix store. nixpkgs 26.05 has no DedSec theme package.
  dedsecTheme = "/boot/grub/themes/dedsec";
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
    theme = lib.mkOption {
      type = lib.types.str;
      default = dedsecTheme;
      description = "GRUB theme directory already on the machine. Documented for bootstrap; not vendored.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      # The live menu lists Manjaro and Windows twice because
      # /etc/grub.d/31_efi_bootnext repeats entries os-prober and 10_linux
      # already emitted. os-prober stays off so this btrfs system is not
      # added a second time. Windows is the single chainloader below.
      useOSProber = false;
      gfxmodeEfi = "auto";
      gfxpayloadEfi = "keep";
      theme = cfg.theme;
      splashImage = null;
      extraEntries = ''
        menuentry "Windows Boot Manager" --class windows --class os {
          insmod part_gpt
          insmod fat
          insmod chain
          search --fs-uuid --no-floppy --set=root 0AF1-1155
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
    boot.loader.efi.efiSysMountPoint = cfg.efiSysMountPoint;
    boot.loader.efi.canTouchEfiVariables = cfg.canTouchEfiVariables;
    boot.loader.timeout = cfg.timeout;
  };
}
