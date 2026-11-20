{ config, lib, pkgs, inputs, ... }:
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
    theme = lib.mkOption {
      type = lib.types.path;
      default = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.grub-theme-dedsec;
      description = "DedSec GRUB theme directory from nur-packages. VandalByte/dedsec-grub2-theme, fuckery at 1440p with color icons.";
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
      # nixpkgs 26.05 defaults this to 100. The installer only stops listing
      # older generations in the submenu. It does not delete profile generations.
      configurationLimit = 20;
      # install-grub.pl: "saved" loads grubenv, sets default to ${saved_entry},
      # defines savedefault, and calls it from each NixOS menu entry.
      default = "saved";
      extraEntries = ''
        menuentry "Windows Boot Manager" --class windows --class os {
          savedefault
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
