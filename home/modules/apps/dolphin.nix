{ lib, pkgs, ... }:
let seed = import ../../lib/seed-config.nix { inherit lib pkgs; };
in {
  home.activation.dolphinPreferences = seed {
    ".config/dolphinrc" = ../../assets/apps/dolphinrc;
  };
}
