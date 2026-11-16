# NetworkManager is the enabled network service.
# Wi-Fi is iwlwifi on Intel AX211 CNVi [8086:51f0].
# Ethernet is r8169 on RTL8111 [10ec:8168].
# No firewalld or ufw unit is enabled on the live system.
{ pkgs, ... }:
{
  networking.useDHCP = false;
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
    networkmanager-l2tp
    networkmanager-openconnect
  ];
  networking.firewall.enable = false;

  hardware.wirelessRegulatoryDatabase = true;
}
