{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.orion.programs.ccSwitch;
  nurPkgs = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.orion.programs.ccSwitch = {
    enable = lib.mkEnableOption "CC Switch and its desktop autostart";
    package = lib.mkPackageOption nurPkgs "cc-switch" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
