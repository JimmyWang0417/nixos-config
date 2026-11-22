{ lib, pkgs, ... }:
let
  seed = import ../../lib/seed-config.nix { inherit lib pkgs; };
in
{
  home.activation.vlcPreferences = seed {
    ".config/vlc/vlcrc" = ../../assets/apps/vlcrc;
  };
}
