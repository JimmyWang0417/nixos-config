{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (import ./assets.nix { inherit pkgs inputs; }) wallpaper;
  # Xfdesktop keys include the actual connector name. Populate the known
  # laptop/external connectors declaratively, and discover active connectors
  # at Xfce login so a differently named output also gets the same wallpaper.
  backdrop = monitor: {
    "backdrop/screen0/monitor${monitor}/workspace0/last-image" = wallpaper;
    "backdrop/screen0/monitor${monitor}/workspace0/image-style" = 5;
    "backdrop/screen0/monitor${monitor}/workspace0/color-style" = 0;
  };
  wallpaperStartup = pkgs.writeShellScript "xfce-whitesur-wallpaper" ''
    ${pkgs.xrandr}/bin/xrandr --query |
      while read -r output state _; do
        if [ "$state" != "connected" ]; then
          continue
        fi
        base="/backdrop/screen0/monitor$output/workspace0"
        ${pkgs.xfconf}/bin/xfconf-query -c xfce4-desktop -p "$base/last-image" \
          --create --type string --set ${lib.escapeShellArg wallpaper}
        ${pkgs.xfconf}/bin/xfconf-query -c xfce4-desktop -p "$base/image-style" \
          --create --type int --set 5
      done
  '';
in
{
  xfconf.settings = {
    xfce4-desktop = {
      "backdrop/single-workspace-mode" = true;
      "backdrop/single-workspace-number" = 0;
      "desktop-icons/icon-size" = 40;
      "desktop-icons/font-size" = 10.0;
    }
    // lib.foldl' (left: right: left // right) { } (
      map backdrop [
        "eDP-1"
        "HDMI-1-0"
        "HDMI-A-1"
        "0"
      ]
    );

  };
  xdg.configFile."autostart/xfce-whitesur-wallpaper.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=WhiteSur wallpaper
    Comment=Use the existing WhiteSur wallpaper on connected Xfce displays
    Exec=${wallpaperStartup}
    OnlyShowIn=XFCE;
    Terminal=false
    StartupNotify=false
  '';
}
