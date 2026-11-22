{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  uint = value: {
    type = "uint";
    inherit value;
  };
  launcher = id: desktop: {
    "plugins/plugin-${toString id}" = "launcher";
    "plugins/plugin-${toString id}/items" = [ desktop ];
  };
  launchers = [
    (launcher 11 "${pkgs.kdePackages.konsole}/share/applications/org.kde.konsole.desktop")
    (launcher 12 "${pkgs.kdePackages.dolphin}/share/applications/org.kde.dolphin.desktop")
    (launcher 13 "${osConfig.programs.firefox.finalPackage}/share/applications/firefox.desktop")
    (launcher 14 "${pkgs.clash-verge-rev}/share/applications/clash-verge.desktop")
    (launcher 15 "${config.programs.vscode.package}/share/applications/code.desktop")
    (launcher 16 "${pkgs.keepassxc}/share/applications/org.keepassxc.KeePassXC.desktop")
    (launcher 17 "${pkgs.todesk}/share/applications/todesk.desktop")
  ];
in
{
  xfconf.settings = {
    xfce4-panel = {
      configver = 2;
      panels = [
        1
        2
      ];
      "panels/dark-mode" = false;
      "panels/panel-1/position" = "p=6;x=0;y=0";
      "panels/panel-1/output-name" = "Primary";
      "panels/panel-1/position-locked" = true;
      "panels/panel-1/size" = uint 44;
      "panels/panel-1/length" = uint 100;
      "panels/panel-1/length-adjust" = false;
      "panels/panel-1/icon-size" = uint 24;
      "panels/panel-1/background-style" = uint 0;
      "panels/panel-1/autohide-behavior" = uint 0;
      "panels/panel-1/plugin-ids" = [
        1
        2
        3
        4
        5
        6
        7
        8
      ];
      "plugins/plugin-1" = "showdesktop";
      "plugins/plugin-2" = "pager";
      "plugins/plugin-2/rows" = uint 2;
      "plugins/plugin-3" = "separator";
      "plugins/plugin-3/expand" = true;
      "plugins/plugin-3/style" = uint 0;
      "plugins/plugin-4" = "systray";
      "plugins/plugin-4/square-icons" = true;
      "plugins/plugin-4/icon-size" = 22;
      "plugins/plugin-5" = "pulseaudio";
      "plugins/plugin-6" = "power-manager-plugin";
      "plugins/plugin-7" = "clock";
      "plugins/plugin-7/mode" = uint 2;
      "plugins/plugin-7/digital-layout" = uint 3;
      "plugins/plugin-7/digital-time-format" = "%m月%d日 周%u  %H:%M";
      "plugins/plugin-7/digital-time-font" = "Noto Sans CJK SC 10";
      "plugins/plugin-8" = "actions";

      "panels/panel-2/position" = "p=10;x=0;y=0";
      "panels/panel-2/output-name" = "Primary";
      "panels/panel-2/position-locked" = true;
      "panels/panel-2/size" = uint 44;
      "panels/panel-2/length" = uint 1;
      "panels/panel-2/length-adjust" = true;
      "panels/panel-2/icon-size" = uint 32;
      "panels/panel-2/background-style" = uint 0;
      "panels/panel-2/autohide-behavior" = uint 1;
      "panels/panel-2/plugin-ids" = [
        10
        11
        12
        13
        14
        15
        16
        17
        18
        19
      ];
      "plugins/plugin-10" = "applicationsmenu";
      "plugins/plugin-10/show-button-title" = false;
      "plugins/plugin-10/button-icon" = "nix-snowflake";
      "plugins/plugin-18" = "separator";
      "plugins/plugin-18/style" = uint 0;
      "plugins/plugin-19" = "tasklist";
      "plugins/plugin-19/show-labels" = false;
      "plugins/plugin-19/grouping" = uint 1;
      "plugins/plugin-19/show-handle" = false;
    }
    // lib.foldl' (left: right: left // right) { } launchers;

  };
}
