{ config, lib, pkgs, ... }:
let
  cfg = config.orion.desktop;
in
{
  options.orion.desktop = {
    enable = lib.mkEnableOption "Plasma desktop";
    defaultSession = lib.mkOption {
      type = lib.types.str;
      default = "plasmax11";
      description = "Login session. plasmax11 is X11. plasma is the Wayland session and stays installed.";
    };
    sddmTheme = lib.mkOption {
      type = lib.types.str;
      default = "breeze";
    };
    autoLogin = {
      enable = lib.mkEnableOption "SDDM autologin";
      user = lib.mkOption {
        type = lib.types.str;
        default = "jimmywang0417";
      };
    };
    touchpad = {
      tapping = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      naturalScrolling = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.displayManager.sddm = {
      enable = true;
      theme = cfg.sddmTheme;
      extraPackages = [ pkgs.qt6.qtvirtualkeyboard ];
      settings = {
        General.InputMethod = "qtvirtualkeyboard";
        Theme.CursorTheme = "breeze_cursors";
      };
    };
    services.displayManager.defaultSession = cfg.defaultSession;
    services.displayManager.autoLogin = lib.mkIf cfg.autoLogin.enable {
      enable = true;
      user = cfg.autoLogin.user;
    };
    services.desktopManager.plasma6.enable = true;

    services.libinput.touchpad = {
      tapping = cfg.touchpad.tapping;
      naturalScrolling = cfg.touchpad.naturalScrolling;
    };
    services.libinput.mouse.accelProfile = "flat";

    environment.systemPackages = with pkgs.kdePackages; [
      ark
      audiocd-kio
      dolphin
      dolphin-plugins
      elisa
      ffmpegthumbs
      filelight
      gwenview
      kamera
      kate
      kaccounts-providers
      kcalc
      kdeconnect-kde
      kdegraphics-thumbnailers
      kdenetwork-filesharing
      keditbookmarks
      kfind
      kgamma
      khelpcenter
      kimageformats
      kinfocenter
      kio-extras
      kmenuedit
      konsole
      ksystemlog
      kwalletmanager
      okular
      phonon-vlc
      plasma-browser-integration
      plasma-systemmonitor
      plasma-thunderbolt
      plasma-workspace-wallpapers
      print-manager
      skanlite
      spectacle
      yakuake
    ] ++ [
      pkgs.tela-icon-theme
      pkgs.papirus-icon-theme
    ];
  };
}
