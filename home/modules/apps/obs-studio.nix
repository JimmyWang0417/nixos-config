{ lib, pkgs, ... }:
let seed = import ../../lib/seed-config.nix { inherit lib pkgs; };
in {
  home.activation.obsstudioPreferences = seed {
    ".config/obs-studio/global.ini" = ../../assets/apps/obs-global.ini;
  };
}
