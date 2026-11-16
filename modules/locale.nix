{ config, lib, ... }:
let
  cfg = config.orion.locale;
in
{
  options.orion.locale = {
    enable = lib.mkEnableOption "locale profile";
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Asia/Shanghai";
    };
    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "zh_CN.UTF-8";
    };
    xkbLayout = lib.mkOption {
      type = lib.types.str;
      default = "cn";
    };
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = cfg.timeZone;
    time.hardwareClockInLocalTime = false;
    services.timesyncd.enable = true;

    i18n.defaultLocale = cfg.defaultLocale;
    i18n.extraLocaleSettings = {
      LC_ADDRESS = cfg.defaultLocale;
      LC_IDENTIFICATION = cfg.defaultLocale;
      LC_MEASUREMENT = cfg.defaultLocale;
      LC_MONETARY = cfg.defaultLocale;
      LC_NAME = cfg.defaultLocale;
      LC_NUMERIC = cfg.defaultLocale;
      LC_PAPER = cfg.defaultLocale;
      LC_TELEPHONE = cfg.defaultLocale;
      LC_TIME = cfg.defaultLocale;
    };
    i18n.supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
    ];

    services.xserver.xkb.layout = cfg.xkbLayout;
  };
}
