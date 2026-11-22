{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Parses plugins.vim and coc.vim. Skips plug.vim, Plug checkouts, and coc
  # extensions that are already on disk, then runs nvim --headless only for
  # what is missing. plugged/ stays out of git.
  installNvimPlugins = pkgs.writeScript "install-nvim-plugins" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ../../install-nvim-plugins.py}
  '';
in
{
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
      pkgs.shfmt
    ];
  };

  # Link individual files so vim-plug can keep writable checkouts alongside.
  xdg.configFile."nvim" = {
    source = ../../nvim;
    recursive = true;
  };

  # After the nvim files are linked. Opening nvim does not run PlugInstall
  # or CocInstall; this does, and a later activation skips what is present.
  home.activation.nvimPlugins =
    lib.hm.dag.entryAfter
      ([ "writeBoundary" ] ++ lib.optional (config.home.activation ? nodeXdgState) "nodeXdgState")
      ''
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
