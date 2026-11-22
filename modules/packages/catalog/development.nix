{ pkgs, ... }:
with pkgs;
[
  cmake
  gnumake
  gdb
  gfortran
  pkg-config
  ninja
  nodejs
  bubblewrap
  python3
  conda
  jdk
  (python3.withPackages (
    ps: with ps; [
      pip
      fastapi
      matplotlib
      pillow
      reportlab
      scikit-learn
      scipy
      seaborn
    ]
  ))
  typst
  pandoc
  jetbrains.idea
  jetbrains.pycharm
  pipx
  shfmt
  tokei
  marksman
  bash-language-server
  universal-ctags
]
