{ pkgs, ... }: {
  xfconf.settings = {
    xfce4-keyboard-shortcuts = {
      "commands/custom/<Primary><Alt>t" = "${pkgs.kdePackages.konsole}/bin/konsole";
      "commands/custom/<Super>e" = "${pkgs.kdePackages.dolphin}/bin/dolphin";
      "commands/custom/<Alt>F1" = "${pkgs.xfce4-appfinder}/bin/xfce4-appfinder";
    };
  };
}
