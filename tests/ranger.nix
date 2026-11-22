{ pkgs }:
pkgs.runCommand "ranger-preview-and-opener-tests"
  {
    nativeBuildInputs = with pkgs; [
      python3
      ranger
      _7zz
      atool
      file
      coreutils
      highlight
      imagemagick
      gnutar
      unzip
      less
      bash
      poppler-utils
    ];
    RANGER_TEST_SCOPE = ../home/ranger/scope.sh;
    RANGER_TEST_RIFLE = ../home/ranger/rifle.conf;
  }
  ''
    ranger_test_state="$TMPDIR/ranger-state"
    export XDG_CONFIG_HOME="$ranger_test_state/config"
    export XDG_DATA_HOME="$ranger_test_state/data"
    export XDG_STATE_HOME="$ranger_test_state/state"
    export XDG_CACHE_HOME="$ranger_test_state/cache"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
    python3 ${./ranger.py}
    touch "$out"
  ''
