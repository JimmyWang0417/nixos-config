{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.orion.development.rust;
  rustupHome = cfg.stateDirectory;
  cargoHome = "${config.home.homeDirectory}/.cargo";
in
{
  options.orion.development.rust = {
    enable = lib.mkEnableOption "rustup-managed Rust toolchains";
    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/rustup";
      description = "Writable NixOS toolchains, separate from legacy ~/.rustup binaries.";
    };
    defaultToolchain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "stable";
      description = "Rust channel downloaded if missing and recorded by rustup at Home Manager activation.";
    };
    components = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [
        "rustfmt"
        "clippy"
        "rust-src"
      ];
      description = "Components installed for the selected default Rust toolchain.";
    };
  };

  config = lib.mkIf cfg.enable {
    # This package supplies the cargo/rustc/rustfmt proxies as well as rustup.
    home.packages = [ pkgs.rustup ];
    home.sessionVariables = {
      RUSTUP_HOME = rustupHome;
      CARGO_HOME = cargoHome;
    };
    systemd.user.sessionVariables = {
      RUSTUP_HOME = rustupHome;
      CARGO_HOME = cargoHome;
    };
    home.activation.rustToolchain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export RUSTUP_HOME=${lib.escapeShellArg rustupHome}
      export CARGO_HOME=${lib.escapeShellArg cargoHome}
      run ${pkgs.rustup}/bin/rustup set profile default
      # rustup default installs a missing toolchain before recording it.
      run ${pkgs.rustup}/bin/rustup default ${lib.escapeShellArg cfg.defaultToolchain}
      ${lib.optionalString (cfg.components != [ ]) ''
        run ${pkgs.rustup}/bin/rustup component add \
          --toolchain ${lib.escapeShellArg cfg.defaultToolchain} \
          ${lib.escapeShellArgs cfg.components}
      ''}
    '';
  };
}
