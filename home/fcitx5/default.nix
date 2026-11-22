{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
{
  # Fcitx's configuration tool edits these files. Deploy writable copies, while
  # keeping learned dictionary/history outside the Nix store and config files.
  home.activation.fcitxConfiguration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/install -Dm644 ${./profile} \
      ${lib.escapeShellArg "${config.xdg.configHome}/fcitx5/profile"}
    run ${pkgs.coreutils}/bin/install -Dm644 ${./conf/pinyin.conf} \
      ${lib.escapeShellArg "${config.xdg.configHome}/fcitx5/conf/pinyin.conf"}
    ${lib.optionalString osConfig.orion.secrets.enable ''
      run ${pkgs.python3}/bin/python3 ${./restore-dictionary.py} \
        --archive ${lib.escapeShellArg osConfig.sops.secrets.fcitx5-pinyin.path} \
        --data-dir ${lib.escapeShellArg "${config.xdg.dataHome}/fcitx5/pinyin"}
    ''}
  '';
}
