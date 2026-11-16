{ config, lib, pkgs, ... }:
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
  # Parses plugins.vim and coc.vim. Skips plug.vim, Plug checkouts, and coc
  # extensions that are already on disk, then runs nvim --headless only for
  # what is missing. plugged/ stays out of git.
  installNvimPlugins = pkgs.writeScript "install-nvim-plugins" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./install-nvim-plugins.py}
  '';
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

  # release-26.05 renamed programs.vscode.extensions to profiles.default.extensions.
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      anthropic.claude-code
      bierner.markdown-preview-github-styles
      catppuccin.catppuccin-vsc-icons
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode
      firefox-devtools.vscode-firefox-debug
      github.vscode-github-actions
      james-yu.latex-workshop
      ms-ceintl.vscode-language-pack-zh-hans
      ms-python.isort
      ms-python.python
      ms-python.vscode-pylance
      ms-python.vscode-python-envs
      ms-toolsai.jupyter
      ms-toolsai.jupyter-keymap
      ms-toolsai.jupyter-renderers
      ms-toolsai.vscode-jupyter-cell-tags
      ms-toolsai.vscode-jupyter-slideshow
      ms-vscode.cmake-tools
      ms-vscode.cpptools
      ms-vscode.cpptools-extension-pack
      ms-vscode.hexeditor
      ms-vscode.remote-explorer
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      mshr-h.veriloghdl
      myriad-dreamin.tinymist
      oracle.oracle-java
      rust-lang.rust-analyzer
      shd101wyy.markdown-preview-enhanced
      teabyii.ayu
      yzhang.markdown-all-in-one
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

    # No tokens in either file. verilog.ctags.path is "ctags" so it resolves
    # to the universal-ctags already in environment.systemPackages.
    "Code/User/settings.json".source = ./vscode/settings.json;
    "Code/User/keybindings.json".source = ./vscode/keybindings.json;
  };

  # After the nvim files are linked. Opening nvim does not run PlugInstall
  # or CocInstall; this does, and a later activation skips what is present.
  home.activation.nvimPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export NVIM=${config.programs.neovim.finalPackage}/bin/nvim
    export GIT=${pkgs.git}/bin/git
    export NODE=${pkgs.nodejs}/bin/node
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export GIT_SSL_CAINFO="$SSL_CERT_FILE"
    export CURL_CA_BUNDLE="$SSL_CERT_FILE"
    export PATH="${
      lib.makeBinPath [
        pkgs.git
        pkgs.nodejs
      ]
    }:$PATH"
    run ${installNvimPlugins}
  '';
}
