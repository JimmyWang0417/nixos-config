{ lib, pkgs, ... }:
let
  seed = import ../../lib/seed-config.nix { inherit lib pkgs; };
in
{
  home.activation.katePreferences = seed {
    ".config/katerc" = ../../assets/apps/katerc;
  };
}
