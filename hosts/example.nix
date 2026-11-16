# Not a real machine, and not referenced by flake.nix.
# Copy to hosts/<name>/default.nix, then add one attribute under nixosConfigurations.
#
# Change these three things:
#   1. networking.hostName, and the matching hostName in flake.nix
#   2. fileSystems, initrd modules, nixos-hardware imports, and GPU bus ids
#   3. which orion.* profiles are enabled
{ config, lib, pkgs, inputs, hostName, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  networking.hostName = "CHANGE-ME";
  system.stateVersion = "26.05";

  # fileSystems."/" = {
  #   device = "/dev/disk/by-uuid/CHANGE-ME";
  #   fsType = "ext4";
  # };

  orion.boot.enable = true;
  orion.chinese.enable = true;
  orion.nix.enable = true;
  orion.shortcuts.profile = "current";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs hostName; };
  home-manager.users.jimmywang0417 = import ../home/jimmy.nix;
}
