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

  # Substituters, the proxy, and http-connections are applied in nix-download.nix.
  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = cfg.allowUnfree;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
  };
}
