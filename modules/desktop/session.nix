# Plasma 6.8 provides the Wayland session only. Keep Xfce X11 selectable for
# ToDesk remote control; both desktops use the same unstable package set.
{ pkgs, ... }:
{
  services.xserver.enable = true;
  services.xserver.xkb.layout = "cn";

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = false;
  services.displayManager.defaultSession = "plasma";
  services.displayManager.autoLogin = {
    enable = true;
    user = "jimmywang0417";
  };
  services.desktopManager.plasma6.enable = true;
  services.xserver.desktopManager.xfce = {
    enable = true;
    enableWaylandSession = false;
  };

}
