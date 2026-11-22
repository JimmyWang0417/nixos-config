{ config, lib, ... }:
{
  config = lib.mkIf config.services.desktopManager.plasma6.enable {
    # Keep the framework for KDE dependencies, but do not run its indexer.
    systemd.user.services.kde-baloo.enable = false;
    environment.etc."xdg/baloofilerc".text = ''
      [Basic Settings]
      Indexing-Enabled[$i]=false
    '';
  };
}
