{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./options.nix
    ./policy.nix
    ./browsers.nix
    ./gaming.nix
  ];

  environment.systemPackages = import ./catalog.nix { inherit config lib pkgs inputs; };
}
