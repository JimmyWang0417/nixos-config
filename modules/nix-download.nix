{ config, lib, pkgs, ... }:
let
  nixCfg = config.orion.nix;
  cfg = nixCfg.download;
  # A narinfo on the USTC store is signed cache.nixos.org-1. The mirror help
  # page does not publish a second key: https://mirrors.ustc.edu.cn/help/nix-channels.html
  officialCacheKey = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
in
{
  options.orion.nix.proxy = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = "http://127.0.0.1:7897";
    example = "http://127.0.0.1:7897";
    description = ''
      Local HTTP proxy for Nix source fetches and for git.
      Clash Verge on this machine listens on mixed port 7897.
      Verge has the separate SOCKS port 7898 and HTTP port 7899 disabled.
      Set to null to fetch directly. This option is not a subscription URL.
    '';
  };

  options.orion.nix.download = {
    enable = lib.mkEnableOption "Nix download timeouts, the local proxy, and Axel";

    httpConnections = lib.mkOption {
      type = lib.types.ints.positive;
      default = 64;
      description = ''
        Value of nix.settings.http-connections.
        64 is Motrix's aria2 max-connection-per-server and split on this machine.
        Nix still uses its own HTTP client for substituters and source fetches.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf nixCfg.chinaMirrors.enable {
      # mkForce keeps a single USTC entry and a single official fallback.
      # The NixOS module also appends cache.nixos.org and the same key.
      nix.settings.substituters = lib.mkForce nixCfg.chinaMirrors.substituters;
      nix.settings.trusted-public-keys = lib.mkForce [ officialCacheKey ];
    })

    (lib.mkIf cfg.enable {
      # Nix 2.34 (nixos-26.05's nixVersions.stable) and 2.35 have no
      # nix.conf keys named http-proxy or https-proxy. Curl reads
      # http_proxy / https_proxy. impure-env forwards those into
      # fixed-output builds; the daemon environment covers substituters
      # and Nix's own fetches.
      nix.settings = {
        connect-timeout = 10;
        http-connections = cfg.httpConnections;
        fallback = true;
      } // lib.optionalAttrs (nixCfg.proxy != null) {
        impure-env = [
          "http_proxy=${nixCfg.proxy}"
          "https_proxy=${nixCfg.proxy}"
          "HTTP_PROXY=${nixCfg.proxy}"
          "HTTPS_PROXY=${nixCfg.proxy}"
        ];
      };

      systemd.services.nix-daemon.environment = lib.optionalAttrs (nixCfg.proxy != null) {
        http_proxy = nixCfg.proxy;
        https_proxy = nixCfg.proxy;
        HTTP_PROXY = nixCfg.proxy;
        HTTPS_PROXY = nixCfg.proxy;
      };

      programs.git = {
        enable = true;
        config = {
          url."https://github.com/".insteadOf = [ "git://github.com/" ];
        } // lib.optionalAttrs (nixCfg.proxy != null) {
          http.proxy = nixCfg.proxy;
        };
      };

      # Axel 2.17.14, same version as ~/.local/bin/axel. No axelrc and no
      # thread-count wrapper on the live system, so this package keeps Axel's
      # own default of 4 connections. Motrix 2.4.1 is not pkgs.motrix 1.8.19.
      environment.systemPackages = [ pkgs.axel ];
    })
  ];
}
