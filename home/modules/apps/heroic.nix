{ lib, pkgs, ... }:
let
  seed = import ../../lib/seed-config.nix { inherit lib pkgs; };
in
{
  home.activation.heroicPreferences = seed {
    ".config/heroic/config.json" = ../../assets/apps/heroic.json;
  };
}
