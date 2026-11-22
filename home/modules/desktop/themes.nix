{ pkgs, inputs, ... }:
let nurPkgs = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
in { home.packages = with nurPkgs; [ tela-icon-theme whitesur-kde breath-wallpapers endeavouros-wallpapers endeavouros-community-wallpapers ]; }
