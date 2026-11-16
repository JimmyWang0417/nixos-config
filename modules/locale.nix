# localectl: LANG=zh_CN.UTF-8, X11 Layout cn, VC keymap unset.
# timedatectl: Asia/Shanghai, NTP active (systemd-timesyncd).
# fcitx5 is installed and GTK_IM_MODULE=fcitx; the user unit was inactive
# at inventory time, but the input method is the configured one.
{ ... }:
{
  time.timeZone = "Asia/Shanghai";
  services.timesyncd.enable = true;

  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };
  i18n.supportedLocales = [
    "zh_CN.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];
}
