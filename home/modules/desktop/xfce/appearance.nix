{ pkgs, inputs, ... }:
let inherit (import ./assets.nix { inherit pkgs inputs; }) theme themeName;
in {
  home.packages = [ theme pkgs.whitesur-cursors ];
  xfconf.settings = {
    xsettings = {
      "Net/ThemeName" = themeName;
      "Net/IconThemeName" = "Tela";
      "Net/EnableEventSounds" = false;
      "Net/EnableInputFeedbackSounds" = false;
      "Gtk/FontName" = "Noto Sans CJK SC 10";
      "Gtk/MonospaceFontName" = "Noto Sans Mono CJK SC 10";
      "Gtk/CursorThemeName" = "WhiteSur-cursors";
      "Gtk/CursorThemeSize" = 32;
      "Gtk/DecorationLayout" = "close,minimize,maximize:";
      "Xft/DPI" = 144;
      "Xft/Antialias" = 1;
      "Xft/Hinting" = 1;
      "Xft/HintStyle" = "hintslight";
      "Xft/RGBA" = "none";
      # Use readable 150% font DPI without a global 2x GTK scale or changing
      # the HDMI output's resolution/transform.
      "Gdk/WindowScalingFactor" = 1;
    };

    xfwm4 = {
      "general/theme" = themeName;
      "general/title_font" = "Noto Sans CJK SC 10";
      "general/button_layout" = "CHM|";
      "general/workspace_count" = 2;
      "general/workspace_names" = [ "默认" "工作" ];
      "general/wrap_workspaces" = false;
      "general/tile_on_move" = true;
      "general/use_compositing" = true;
    };

  };
}
