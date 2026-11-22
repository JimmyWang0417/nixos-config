# Pure package catalog; these lists do not configure services or user files.
{
  config,
  lib,
  pkgs,
  inputs,
}:
let
  args = { inherit config pkgs inputs; };
  groups = [
    ./catalog/core.nix
    ./catalog/development.nix
    ./catalog/desktop-apps.nix
    ./catalog/storage.nix
    ./catalog/hardware.nix
    ./catalog/media.nix
    ./catalog/desktop-tools.nix
  ];
in
lib.concatMap (group: import group args) groups ++ config.orion.packages.unstable
