{
  config,
  lib,
  pkgs,
  ...
}:
let
  runtimeDirectory = "nix-adaptive-gc";
  runtimeConfig = "/run/${runtimeDirectory}/settings.conf";
in
{
  config = lib.mkIf config.orion.nix.storage.enable {
    # Optional at build/check time; generated before the real daemon starts.
    nix.extraOptions = ''
      !include ${runtimeConfig}
    '';
    systemd.services.nix-daemon = {
      serviceConfig.RuntimeDirectory = [ runtimeDirectory ];
      serviceConfig.RuntimeDirectoryMode = "0755";
      preStart = lib.mkBefore ''
        ${pkgs.python3}/bin/python3 ${./adaptive-gc.py} \
          --store /nix/store --output ${runtimeConfig}
      '';
    };
  };
}
