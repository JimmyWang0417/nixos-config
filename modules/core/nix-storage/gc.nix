{ config, lib, ... }:
{
  config = lib.mkIf config.orion.nix.storage.enable {
    # Age-based profile cleanup is independent of the GRUB menu limit.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
      options = "--delete-older-than 30d";
    };
  };
}
