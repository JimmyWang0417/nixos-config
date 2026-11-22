{ pkgs }:
let
  source = pkgs.lib.fileset.toSource {
    root = ../.;
    fileset = pkgs.lib.fileset.unions [
      ./node-xdg.py
      ../home/modules/development/node
    ];
  };
in
pkgs.runCommand "node-xdg-state-tests"
  {
    nativeBuildInputs = with pkgs; [
      python3
      bash
      nodejs
    ];
  }
  ''
    python3 ${source}/tests/node-xdg.py
    touch "$out"
  ''
