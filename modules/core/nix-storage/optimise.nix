{ config, lib, ... }:
{
  config = lib.mkIf config.orion.nix.storage.enable {
    nix.optimise = {
      automatic = true;
      dates = [ "Mon *-*-* 04:00:00" ];
      persistent = true;
    };
    # The upstream service already uses idle scheduling and requires AC power.
    # Deduplicate in that job rather than adding work to every store insertion.
    nix.settings.auto-optimise-store = lib.mkDefault false;
  };
}
