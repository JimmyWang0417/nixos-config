# Build with: nix build --impure --no-link --file tests/xfce-assets.nix
# Check the names that Xfce actually requests against the installed assets.
let
  flake = builtins.getFlake (toString ../.);
  system = flake.nixosConfigurations.orion;
  pkgs = system.pkgs;
  home = system.config.home-manager.users.jimmywang0417;
  settings = home.xfconf.settings;
  theme = pkgs.lib.findFirst (
    package: (package.pname or "") == "whitesur-gtk-theme"
  ) null home.home.packages;
  nurPkgs = flake.inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
  gtkName = settings.xsettings."Net/ThemeName";
  wmName = settings.xfwm4."general/theme";
in
assert theme != null;
pkgs.runCommand "xfce-appearance-assets" { } ''
  test -s ${theme}/share/themes/${gtkName}/gtk-3.0/gtk.css
  test -s ${theme}/share/themes/${wmName}/xfwm4/themerc
  test -s ${pkgs.whitesur-cursors}/share/icons/${
    settings.xsettings."Gtk/CursorThemeName"
  }/cursors/left_ptr
  test -s ${nurPkgs.tela-icon-theme}/share/icons/${settings.xsettings."Net/IconThemeName"}/index.theme
  test -s ${
    pkgs.lib.escapeShellArg settings.xfce4-desktop."backdrop/screen0/monitoreDP-1/workspace0/last-image"
  }
  mkdir -p "$out"
  printf '%s\n' 'GTK, xfwm4, cursor, Tela and WhiteSur wallpaper assets verified' > "$out/result"
''
