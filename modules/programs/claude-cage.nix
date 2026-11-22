{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.orion.programs.claudeCage;
in
{
  options.orion.programs.claudeCage = {
    enable = lib.mkEnableOption "the official Claude Cage VM desktop environment";
    package = lib.mkOption {
      type = lib.types.package;
      default = import ../../packages/claude-cage { inherit pkgs; };
      description = "Official stable desktop bundle with host dependencies from the global package set.";
    };
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Existing users needing KVM access for local Cage guests; unnecessary for remote-only use. Existing host KVM membership can be reused.";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    users.users = lib.genAttrs cfg.users (_: {
      extraGroups = [ "kvm" ];
    });
  };
}
