{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.orion.chinese.enable {
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
        carlito
        caladea
        dejavu_fonts
        inconsolata
        terminus_font
      ];
      # /etc/fonts/conf.d. Qt 6, GTK 3, and GTK 4 read fontconfig on
      # Wayland; nothing here is installed only for X11.
      fontconfig = {
        enable = true;
        antialias = true;
        hinting.enable = true;
        hinting.style = "slight";
        subpixel.lcdfilter = "default";
        # Plasma 6 also assigns defaultFonts (Hack, Noto Sans). mkForce keeps
        # this chain first. Win10 fonts stay installed and stay off this list.
        defaultFonts = {
          sansSerif = lib.mkForce [ "Noto Sans CJK SC" "Noto Sans" "Source Sans 3" "DejaVu Sans" ];
          serif = lib.mkForce [ "Noto Serif CJK SC" "Noto Serif" "DejaVu Serif" ];
          monospace = lib.mkForce [ "Noto Sans Mono CJK SC" "Inconsolata" "DejaVu Sans Mono" ];
          emoji = lib.mkForce [ "Noto Color Emoji" ];
        };
      };
    };

  };
}
