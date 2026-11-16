{ config, lib, pkgs, ... }:
let
  cfg = config.orion.chinese;
in
{
  options.orion.chinese.enable = lib.mkEnableOption "fcitx5 and CJK fonts";

  config = lib.mkIf cfg.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-gtk
        qt6Packages.fcitx5-configtool
        qt6Packages.fcitx5-qt
      ];
    };

    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        wqy_microhei
        source-sans-pro
        liberation_ttf
        dejavu_fonts
        inconsolata
        terminus_font
      ];
      fontconfig = {
        antialias = true;
        hinting.enable = true;
        hinting.style = "slight";
        subpixel.lcdfilter = "default";
        defaultFonts = {
          sansSerif = [ "Noto Sans CJK SC" "Noto Sans" "Source Sans 3" "DejaVu Sans" ];
          serif = [ "Noto Serif CJK SC" "Noto Serif" "DejaVu Serif" ];
          monospace = [ "Noto Sans Mono CJK SC" "Inconsolata" "DejaVu Sans Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };
  };
}
