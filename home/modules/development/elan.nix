{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.orion.development.elan;
  elanHome = cfg.stateDirectory;
in
{
  options.orion.development.elan = {
    enable = lib.mkEnableOption "elan-managed Lean toolchains";
    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/elan";
      description = "Writable NixOS toolchain data, separate from legacy ~/.elan binaries.";
    };
    defaultToolchain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "stable";
      description = "Lean channel installed and recorded by elan during Home Manager activation.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.elan ];
    home.sessionVariables.ELAN_HOME = elanHome;
    systemd.user.sessionVariables.ELAN_HOME = elanHome;
    home.activation.elanToolchain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export ELAN_HOME=${lib.escapeShellArg elanHome}
      # elan 4.3 default only writes the preference. Install explicitly first.
      run ${pkgs.elan}/bin/elan toolchain install ${lib.escapeShellArg cfg.defaultToolchain}
      run ${pkgs.elan}/bin/elan default ${lib.escapeShellArg cfg.defaultToolchain}
    '';
  };
}
