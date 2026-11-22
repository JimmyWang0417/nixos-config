{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Community plugins remain managed by dsh-market, not pinned by Nix.
  dsh = lib.findFirst (
    pkg: (pkg.pname or "") == "deepseek-harness"
  ) null config.orion.packages.unstable;
in
{
  assertions = [
    {
      assertion = config.orion.packages.dshPlugins == [ ] || dsh != null;
      message = "orion.packages.dshPlugins requires deepseek-harness on orion.packages.unstable.";
    }
  ];

  # Home-manager module, so lib.hm exists. Missing names go through
  # `dsh plugin add` with no version. A dependency whose key and spec are both
  # absent from this list is removed. A saved registry spec that is still listed
  # stays so dsh-market can update it. A Nix link: or file: spec is replaced.
  home-manager.users.jimmywang0417 = { lib, ... }: {
    config = lib.mkIf (config.orion.packages.dshPlugins != [ ] && dsh != null) {
      home.activation.dshPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        export DSH=${dsh}/bin/dsh
        export DSH_PLUGIN_NAMES=${lib.escapeShellArg (builtins.toJSON config.orion.packages.dshPlugins)}
        ${pkgs.python3}/bin/python3 ${./reconcile-plugins.py}
      '';
    };
  };
}
