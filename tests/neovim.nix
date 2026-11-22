{
  pkgs,
  neovim ? pkgs.neovim-unwrapped,
}:
pkgs.runCommand "neovim-command-behavior"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    NVIM_BIN = "${neovim}/bin/nvim";
    NVIM_CONFIG_SOURCE = ../home/nvim;
  }
  ''
    python3 ${./neovim.py}
    touch "$out"
  ''
