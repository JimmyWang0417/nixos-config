let
  flake = builtins.getFlake (toString ../.);
  system = flake.nixosConfigurations.orion;
  home = system.config.home-manager.users.jimmywang0417;
  inherit (system.pkgs) lib;
  withoutNode =
    (system.extendModules {
      modules = [
        {
          home-manager.users.jimmywang0417.disabledModules = [
            (flake.outPath + "/home/modules/development/node")
          ];
        }
      ];
    }).config.home-manager.users.jimmywang0417;
  expected = {
    NPM_CONFIG_USERCONFIG = "${home.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_CACHE = "${home.xdg.cacheHome}/npm";
    NPM_CONFIG_PREFIX = "${home.xdg.dataHome}/npm";
    NODE_REPL_HISTORY = "${home.xdg.stateHome}/node/repl_history";
  };
  checks = {
    sessionAndServicesAgree = builtins.all (
      name:
      home.home.sessionVariables.${name} == expected.${name}
      && home.systemd.user.sessionVariables.${name} == expected.${name}
    ) (builtins.attrNames expected);
    globalBinNotPrepended = !(builtins.elem "${home.xdg.dataHome}/npm/bin" home.home.sessionPath);
    migrationAfterWriteBoundary = builtins.elem "writeBoundary" home.home.activation.nodeXdgState.after;
    activationExportsEnvironment = lib.hasInfix (home.lib.shell.exportAll expected) home.home.activation.nodeXdgState.data;
    npmInstallerAfterMigration = builtins.elem "nodeXdgState" home.home.activation.nvimPlugins.after;
    editorWorksWithoutNodeModule =
      !(withoutNode.home.activation ? nodeXdgState)
      && !(builtins.elem "nodeXdgState" withoutNode.home.activation.nvimPlugins.after)
      && builtins.elem "writeBoundary" withoutNode.home.activation.nvimPlugins.after;
    credentialsNotDeclarative = !(home.xdg.configFile ? "npm/npmrc");
  };
  failed = builtins.filter (name: !checks.${name}) (builtins.attrNames checks);
in
if failed != [ ] then
  throw "Node XDG regression: ${builtins.concatStringsSep ", " failed}"
else
  checks
