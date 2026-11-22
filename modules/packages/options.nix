{ lib, pkgs, ... }:
{
  options.orion.packages.unstable = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [
      pkgs.deepseek-harness
      pkgs.claude-code
      pkgs.codex
      pkgs.android-studio
      # udev rules for this derivation are installed by modules/services.nix.
      pkgs.openlogi
    ];
    description = "Additional applications from the global unstable package set. All other system and Home Manager packages use this same set.";
  };

}
