# KDE Plasma 6.7 on Wayland, SDDM 0.21. The greeter is also started on Wayland.
{ pkgs, ... }:
{
  services.xserver.enable = true;
  services.xserver.xkb.layout = "cn";

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.defaultSession = "plasma";
  # /etc/sddm.conf.d/kde_settings.conf autologins this user. The file names
  # Session=plasmax11, while the running session is Wayland (plasma).
  services.displayManager.autoLogin = {
    enable = true;
    user = "jimmywang0417";
  };
  services.desktopManager.plasma6.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };
  security.rtkit.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  environment.systemPackages = with pkgs; [
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.elisa
    kdePackages.filelight
    kdePackages.gwenview
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.kdeconnect-kde
    kdePackages.kfind
    kdePackages.konsole
    kdePackages.kwalletmanager
    kdePackages.okular
    kdePackages.skanlite
    kdePackages.spectacle
    kdePackages.yakuake
  ];
}
