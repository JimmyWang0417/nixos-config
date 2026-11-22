{ lib, pkgs, ... }:
let
  # Commands actually invoked by the migrated ranger preview/opener scripts.
  previewCommands = with pkgs; [
    w3m
    atool
    mediainfo
    ffmpegthumbnailer
    poppler-utils
    djvulibre
    libarchive
    imagemagick
  ];
in
{
  home.packages = previewCommands;
  programs.ranger = {
    enable = true;
    extraPackages = previewCommands;
  };

  xdg.configFile = {
    "ranger/rc.conf".text = lib.mkForce (builtins.readFile ../../ranger/rc.conf);
    "ranger/rifle.conf".source = ../../ranger/rifle.conf;
    "ranger/commands.py".source = ../../ranger/commands.py;
    "ranger/scope.sh" = {
      source = ../../ranger/scope.sh;
      executable = true;
    };
    "ranger/colorschemes/__init__.py".source = ../../ranger/colorschemes/__init__.py;
    "ranger/colorschemes/default.py".source = ../../ranger/colorschemes/default.py;
    "ranger/colorschemes/jungle.py".source = ../../ranger/colorschemes/jungle.py;
    "ranger/colorschemes/snow.py".source = ../../ranger/colorschemes/snow.py;
    "ranger/colorschemes/zenburn.py".source = ../../ranger/colorschemes/zenburn.py;
    "ranger/plugins/__init__.py".source = ../../ranger/plugins/__init__.py;
    "ranger/plugins/devicons.py".source = ../../ranger/plugins/devicons.py;
    "ranger/plugins/devicons_linemode.py".source = ../../ranger/plugins/devicons_linemode.py;
  };
}
