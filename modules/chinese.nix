{ config, lib, pkgs, ... }:
let
  cfg = config.orion.chinese;
  # fcitx5-with-addons from i18n.inputMethod.fcitx5. QT_PLUGIN_PATH must
  # point at this output so the Qt 6 immodule is the wrapped one.
  fcitxPluginPath = "${config.i18n.inputMethod.package}/${pkgs.qt6.qtbase.qtPluginPrefix}";
  fcitxDesktop = "${config.i18n.inputMethod.package}/share/applications/org.fcitx.Fcitx5.desktop";
in
{
  options.orion.chinese.enable = lib.mkEnableOption "fcitx5 and CJK fonts";

  config = lib.mkIf cfg.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      # nixpkgs 26.05: waylandFrontend sets XMODIFIERS and QT_PLUGIN_PATH,
      # and leaves GTK_IM_MODULE and QT_IM_MODULE unset. Plasma Wayland GTK
      # then uses text-input-v3. Forcing GTK_IM_MODULE=fcitx makes the
      # candidate window blink.
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-gtk
        qt6Packages.fcitx5-configtool
        qt6Packages.fcitx5-qt
      ];
    };

    # Those two nixpkgs variables are environment.variables only. SDDM's
    # Wayland session does not source /etc/profile; PAM reads
    # sessionVariables. Repeat them here, and fill what 26.05 does not set:
    # SDL, Qt 6's module list, and the nixpkgs Ozone hint for Electron
    # and Chromium (--enable-wayland-ime only when WAYLAND_DISPLAY is set).
    environment.sessionVariables = {
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
      NIXOS_OZONE_WL = "1";
      # Qt 6.7+ (this nixpkgs is 6.11). Wayland text-input first, then the
      # fcitx plugin, then ibus for toolkits that only ship that plugin.
      # QT_IM_MODULE stays unset so this list is what Qt 6 consults.
      QT_IM_MODULES = "wayland;fcitx;ibus";
      QT_PLUGIN_PATH = [ fcitxPluginPath ];
    };

    # fcitx5.nix sets this as a list. Copying sessionVariables turns the
    # same path into a string. A plain value outranks mkOverride 900, so
    # mkForce is what keeps the two from aborting evaluation.
    environment.variables.QT_PLUGIN_PATH = lib.mkForce [ fcitxPluginPath ];

    # startplasma sources this before apps, after SDDM has set
    # XDG_SESSION_TYPE. X11 needs the immodules. Wayland must not.
    # A gtk settings.ini is not used: GTK reads the first settings.ini
    # it finds, so a file that only sets the immodule would hide the
    # Plasma theme.
    environment.etc."xdg/plasma-workspace/env/fcitx5.sh".text = ''
      if [ "''${XDG_SESSION_TYPE:-}" != "wayland" ]; then
        export GTK_IM_MODULE=fcitx
        export QT_IM_MODULE=fcitx
        unset ELECTRON_OZONE_PLATFORM_HINT
      else
        # Electron reads this itself. plasmax11 leaves it unset so ToDesk
        # still sees X11 clients. NIXOS_OZONE_WL above is what the nixpkgs
        # wrappers turn into Wayland flags, and only when WAYLAND_DISPLAY is set.
        export ELECTRON_OZONE_PLATFORM_HINT=auto
      fi
    '';

    # KWin has to launch fcitx5 so the Wayland input-method socket exists.
    # The path is this generation's wrapped desktop file, not /usr.
    environment.etc."xdg/kwinrc".text = ''
      [Wayland]
      InputMethod=${fcitxDesktop}
    '';

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

    assertions = [
      {
        assertion = !(config.environment.sessionVariables ? GTK_IM_MODULE);
        message = "GTK_IM_MODULE stays unset; Plasma Wayland GTK uses text-input-v3";
      }
      {
        assertion = !(config.environment.sessionVariables ? QT_IM_MODULE);
        message = "QT_IM_MODULE stays unset; Qt 6 uses QT_IM_MODULES";
      }
      {
        assertion = config.services.displayManager.defaultSession == "plasmax11";
        message = "Default Plasma session stays plasmax11";
      }
    ];
  };
}
