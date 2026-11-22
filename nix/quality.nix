{
  inputs,
  self,
  pkgs,
}:
let
  treefmt = inputs.treefmt-nix.lib.evalModule pkgs ../treefmt.nix;
  hooks = inputs.git-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
    src = self;
    hooks = {
      actionlint = {
        enable = true;
        package = pkgs.actionlint;
      };
      treefmt = {
        enable = true;
        packageOverrides.treefmt = treefmt.config.build.wrapper;
        files = "\\.(nix|py|sh)$";
      };
      statix = {
        enable = true;
        package = pkgs.statix;
        settings.config = "statix.toml";
      };
      deadnix = {
        enable = true;
        package = pkgs.deadnix;
        # NixOS/HM modules conventionally list optional arguments in {...}.
        settings.noLambdaPatternNames = true;
      };
    };
  };
in
{
  formatter = treefmt.config.build.wrapper;
  checks = {
    formatting = treefmt.config.build.check self;
    pre-commit = hooks;
  };
  packages = [ treefmt.config.build.wrapper ] ++ hooks.enabledPackages;
  shellHook = hooks.shellHook;
}
