{ lib, pkgs, ... }:
let
  seed = import ../../lib/seed-config.nix { inherit lib pkgs; };
in
{
  home.activation.btopPreferences = seed {
    ".config/btop/btop.conf" = ../../assets/apps/btop.conf;
  };
}
