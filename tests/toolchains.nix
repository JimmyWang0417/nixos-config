let
  flake = builtins.getFlake (toString ../.);
  system = flake.nixosConfigurations.orion;
  pkgs = system.pkgs;
  home = system.config.home-manager.users.jimmywang0417;
  names = map (p: p.pname or p.name) home.home.packages;
  checks = {
    elanDefaultStable = home.orion.development.elan.enable
      && home.orion.development.elan.defaultToolchain == "stable";
    rustDefaultStable = home.orion.development.rust.enable
      && home.orion.development.rust.defaultToolchain == "stable";
    unstableElanInstalled = builtins.any (p: p.drvPath == pkgs.elan.drvPath) home.home.packages;
    unstableRustupInstalled = builtins.any (p: p.drvPath == pkgs.rustup.drvPath) home.home.packages;
    noCompetingRustPackages = builtins.all (name: !(builtins.elem name names)) [ "cargo" "rustc" "rustfmt" ];
    isolatedNixToolchains = home.home.sessionVariables.ELAN_HOME != "${home.home.homeDirectory}/.elan"
      && home.home.sessionVariables.RUSTUP_HOME != "${home.home.homeDirectory}/.rustup";
    userServiceEnvironment = home.systemd.user.sessionVariables.ELAN_HOME == home.home.sessionVariables.ELAN_HOME
      && home.systemd.user.sessionVariables.RUSTUP_HOME == home.home.sessionVariables.RUSTUP_HOME
      && home.systemd.user.sessionVariables.CARGO_HOME == home.home.sessionVariables.CARGO_HOME;
    rustSourceAndTools = builtins.all
      (name: builtins.elem name home.orion.development.rust.components)
      [ "rust-src" "rustfmt" "clippy" ];
    installsAfterWriteBoundary = builtins.elem "writeBoundary" home.home.activation.elanToolchain.after
      && builtins.elem "writeBoundary" home.home.activation.rustToolchain.after;
  };
  failures = builtins.filter (name: !checks.${name}) (builtins.attrNames checks);
in
if failures != [ ] then throw "Toolchain policy regression: ${builtins.concatStringsSep ", " failures}"
else {
  inherit checks;
  homeDirectory = home.home.homeDirectory;
  elanProgram = "${pkgs.elan}/bin/elan";
  rustupProgram = "${pkgs.rustup}/bin/rustup";
  elanActivation = home.home.activation.elanToolchain.data;
  rustActivation = home.home.activation.rustToolchain.data;
}
