# DevEco joins the system from one impure rebuild.
#
# `nixos-rebuild switch --impure` can see this machine. When
# ~/.config/hdx/credentials.json exists, evaluation runs fetch-deveco,
# which refreshes the local hdx login and puts the two archives in the
# store. The package derivation only receives those store paths. A pure
# rebuild cannot see the home directory or the Nix store, so it does not
# call hdx and does not install DevEco.
{ lib, pkgs, inputs, ... }:
let
  # users.nix does not set home, so NixOS uses /home/<name>. Reading that
  # option here would loop through the module config.
  home = "/home/jimmywang0417";
  creds = "${home}/.config/hdx/credentials.json";
  # Pure flake evaluation makes pathExists false for every absolute path.
  impure = builtins.pathExists /etc/hostname || builtins.pathExists creds;
  haveCreds = builtins.pathExists creds;
  login = "run `hdx auth login` on this machine";
in
{
  config =
    if !impure then
      {
        warnings = [
          "DevEco Studio was not downloaded. Re-run `nixos-rebuild switch --impure --flake .#orion` after `hdx auth login` on this machine."
        ];
      }
    else if !haveCreds then
      {
        assertions = [
          {
            assertion = false;
            message = login;
          }
        ];
      }
    else
      let
        system = pkgs.stdenv.hostPlatform.system;
        fetch = inputs.nur-packages.apps.${system}.fetch-deveco.program;
        # currentTime keeps the derivation from being reused, so an impure
        # rebuild downloads again. The signed URL is produced by hdx at run
        # time and is not part of this derivation.
        archives = pkgs.runCommand "deveco-archives-${toString builtins.currentTime}" {
          nativeBuildInputs = [ pkgs.python3 ];
          preferLocalBuild = true;
          allowSubstitutes = false;
          __noChroot = true;
        } ''
          set -eu
          export HOME=${lib.escapeShellArg home}
          export XDG_CONFIG_HOME="$HOME/.config"
          if [ ! -s "$HOME/.config/hdx/credentials.json" ]; then
            echo ${lib.escapeShellArg login} >&2
            exit 1
          fi
          mkdir -p "$out"
          ${fetch} --output-dir "$out"
        '';
        hashes = builtins.readFile "${archives}/.hashes";
        deveco = inputs.nur-packages.packages.${system}.deveco-studio.override {
          macZip = "${archives}/mac.zip";
          cliZip = "${archives}/cli.zip";
        };
      in
      if builtins.match ".*://.*" hashes != null then
        {
          assertions = [
            {
              assertion = false;
              message = "refusing a download URL";
            }
          ];
        }
      else
        {
          environment.systemPackages = [ deveco ];
        };
}
