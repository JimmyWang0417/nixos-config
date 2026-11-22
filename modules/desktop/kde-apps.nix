{ pkgs, ... }: {
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
