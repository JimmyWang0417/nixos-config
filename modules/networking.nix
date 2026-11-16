{ config, lib, pkgs, ... }:
let
  cfg = config.orion.networking;
in
{
  options.orion.networking = {
    enable = lib.mkEnableOption "NetworkManager profile";
    kdeconnectPorts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open TCP/UDP 1714-1764 so KDE Connect still works with the firewall on.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openvpn
        networkmanager-l2tp
        networkmanager-openconnect
      ];
    };
    networking.useDHCP = false;
    networking.firewall.allowedTCPPortRanges = lib.mkIf cfg.kdeconnectPorts [
      { from = 1714; to = 1764; }
    ];
    networking.firewall.allowedUDPPortRanges = lib.mkIf cfg.kdeconnectPorts [
      { from = 1714; to = 1764; }
    ];
  };
}
