{
  config,
  lib,
  pkgs,
  ...
}:
let
  environment = {
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/repl_history";
  };
in
{
  home.sessionVariables = environment;
  systemd.user.sessionVariables = environment;
  # The npmrc stays writable and is never read into an evaluation or the store.
  home.activation.nodeXdgState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Activation is not a user shell; later installers must inherit these too.
    ${config.lib.shell.exportAll environment}
    run ${pkgs.python3}/bin/python3 ${./migrate.py} \
      --home ${lib.escapeShellArg config.home.homeDirectory} \
      --config ${lib.escapeShellArg config.xdg.configHome} \
      --cache ${lib.escapeShellArg config.xdg.cacheHome} \
      --data ${lib.escapeShellArg config.xdg.dataHome} \
      --state ${lib.escapeShellArg config.xdg.stateHome}
  '';
  xdg.configFile."node/env.sh".source = ./env.sh;
  # home.sessionPath prepends, so use the final shell fragment to append instead.
  home.sessionVariablesExtra = ''
    . ${lib.escapeShellArg "${config.xdg.configHome}/node/env.sh"}
  '';
}
