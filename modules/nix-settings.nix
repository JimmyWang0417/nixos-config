{ config, lib, ... }:
let
  cfg = config.orion.nix;
in
{
  options.orion.nix = {
    enable = lib.mkEnableOption "flakes and the Nix daemon settings";
    allowUnfree = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Needed for the NVIDIA userspace driver and the unfree apps installed on Orion.";
    };
    chinaMirrors.enable = lib.mkEnableOption "USTC Nix substituter";
    chinaMirrors.substituters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = cfg.allowUnfree;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.substituters = lib.mkIf cfg.chinaMirrors.enable cfg.chinaMirrors.substituters;
    nix.settings.trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
}
