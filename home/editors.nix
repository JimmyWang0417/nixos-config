{ lib, pkgs, ... }:
let
  # Commands scope.sh / rifle.conf / rc.conf actually run.
  # nixpkgs ranger already wraps file, coreutils, and ImageMagick, and bakes
  # w3mimgdisplay's store path into img_display.py. These still need to be on
  # PATH for `w3m -dump`, archive listing, and the other preview commands.
  rangerCommands = [
    pkgs.w3m
    pkgs.atool
    pkgs.mediainfo
    pkgs.ffmpegthumbnailer
    pkgs."poppler-utils"
    pkgs.djvulibre
    pkgs.libarchive
    pkgs.imagemagick
  ];
in
{
  home.packages = rangerCommands;

  programs.ranger = {
    enable = true;
    extraPackages = rangerCommands;
  };

  programs.neovim = {
    enable = true;
    withPython3 = true;
    withNodeJs = true;
    extraPython3Packages = ps: [ ps.black ];
    extraPackages = [
      pkgs.gcc
      pkgs."clang-tools"
      pkgs."efm-langserver"
      pkgs.black
    ];
  };

  xdg.configFile = {
    # programs.ranger always writes rc.conf. Keep the migrated file.
    "ranger/rc.conf".text = lib.mkForce (builtins.readFile ./ranger/rc.conf);
    "ranger/rifle.conf".source = ./ranger/rifle.conf;
    "ranger/commands.py".source = ./ranger/commands.py;
    "ranger/scope.sh" = {
      source = ./ranger/scope.sh;
      executable = true;
    };
    "ranger/colorschemes/__init__.py".source = ./ranger/colorschemes/__init__.py;
    "ranger/colorschemes/default.py".source = ./ranger/colorschemes/default.py;
    "ranger/colorschemes/jungle.py".source = ./ranger/colorschemes/jungle.py;
    "ranger/colorschemes/snow.py".source = ./ranger/colorschemes/snow.py;
    "ranger/colorschemes/zenburn.py".source = ./ranger/colorschemes/zenburn.py;
    "ranger/plugins/__init__.py".source = ./ranger/plugins/__init__.py;
    "ranger/plugins/devicons.py".source = ./ranger/plugins/devicons.py;
    "ranger/plugins/devicons_linemode.py".source = ./ranger/plugins/devicons_linemode.py;

    # File links, not a store symlink of the whole directory, so vim-plug can
    # create ~/.config/nvim/plugged beside them.
    "nvim" = {
      source = ./nvim;
      recursive = true;
    };
  };
}
