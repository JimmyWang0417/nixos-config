# docker-easyconnect follows campus reachability.
# A campus-only HTTPS probe that completes with HTTP 2xx/3xx starts the
# container. DNS alone does not. A redirect to a different host does not.
# If every probe fails, the container stops, even when a recorded SSID is up.
# The OCI unit is not wanted by the default target; the dispatcher uses
# `docker start` / `docker stop`. No VPN password is stored here.
{ config, lib, pkgs, ... }:
let
  cfg = config.orion.easyconnect;
  containerName = "easyconnect";
  image = "hagb/docker-easyconnect:7.6.7";
  dataVolume = "easyconnect-data:/root";
  docker = config.virtualisation.docker.package;
  curl = "${pkgs.curl}/bin/curl";
  tr = "${pkgs.coreutils}/bin/tr";
  # Authority only: userinfo is the part before '@' and before the path.
  probeAuthority = url:
    let
      rest = lib.removePrefix "https://" url;
      noPath = lib.head (lib.splitString "/" rest);
      noQuery = lib.head (lib.splitString "?" noPath);
      noFrag = lib.head (lib.splitString "#" noQuery);
    in
    noFrag;
  probeOk = url:
    lib.hasPrefix "https://" url
    && url != "https://"
    && probeAuthority url != ""
    && !lib.hasInfix "@" (probeAuthority url)
    && !lib.hasInfix " " url
    && !lib.hasInfix "\n" url;
  probe = pkgs.writeShellScript "easyconnect-campus-probe" ''
    # Exit 0 only after a direct HTTPS response.
    # 2xx is success. 3xx is success only when Location is empty, relative,
    # or names the same host. Another host is a captive-portal redirect.
    set -eu
    url="''${1:-}"
    case "$url" in
      https://*@*)
        exit 1
        ;;
      https://?*)
        ;;
      *)
        exit 1
        ;;
    esac

    host_of() {
      local u="$1"
      case "$u" in
        //*)
          u="''${u#//}"
          ;;
        *://*)
          u="''${u#*://}"
          ;;
      esac
      u="''${u%%/*}"
      u="''${u%%\?*}"
      u="''${u%%#*}"
      u="''${u##*@}"
      case "$u" in
        \[*\])
          u="''${u#\[}"
          u="''${u%%\]*}"
          ;;
        *:*)
          u="''${u%%:*}"
          ;;
      esac
      case "$u" in
        *.)
          u="''${u%.}"
          ;;
      esac
      printf '%s' "$u" | ${tr} '[:upper:]' '[:lower:]'
    }

    origin="$(host_of "$url")"
    [ -n "$origin" ] || exit 1

    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy

    # --max-redirs 0 keeps the first response. A portal 302 to another host
    # must not be followed into a 200 that would look like success.
    # Connect budget is 3s. --max-time 5 covers DNS plus the status line.
    if ! meta="$(
      ${curl} \
        --silent \
        --show-error \
        --output /dev/null \
        --proxy "" \
        --noproxy '*' \
        --connect-timeout 3 \
        --max-time 5 \
        --max-redirs 0 \
        --proto '=https' \
        --proto-redir '=https' \
        --write-out '%{http_code}\n%{redirect_url}' \
        -- "$url"
    )"; then
      exit 1
    fi

    case "$meta" in
      *$'\n'*)
        code="''${meta%%$'\n'*}"
        redir="''${meta#*$'\n'}"
        ;;
      *)
        code="$meta"
        redir=""
        ;;
    esac

    case "$code" in
      2[0-9][0-9])
        exit 0
        ;;
      3[0-9][0-9])
        ;;
      *)
        exit 1
        ;;
    esac

    [ -z "$redir" ] && exit 0
    case "$redir" in
      https://*|http://*|//*)
        ;;
      /*)
        exit 0
        ;;
      *)
        exit 1
        ;;
    esac

    target="$(host_of "$redir")"
    [ -n "$target" ] && [ "$target" = "$origin" ]
  '';
  dispatcher = pkgs.writeShellScript "easyconnect-nm-dispatcher" ''
    action="''${2:-}"
    case "$action" in
      up|down|vpn-up|vpn-down|connectivity-change|dhcp4-change|dhcp6-change) ;;
      *) exit 0 ;;
    esac

    # campusConnections / campusSubnets are not consulted. A probe that
    # completes starts the container even when the SSID is absent from
    # that list. A failed probe stops it even when the SSID matches.
    on_campus=0
    set -- ${lib.escapeShellArgs cfg.campusProbes}
    for url in "$@"; do
      [ -n "$url" ] || continue
      if ${probe} "$url"; then
        on_campus=1
        break
      fi
    done

    if [ "$on_campus" -eq 1 ]; then
      if ! ${docker}/bin/docker container inspect ${containerName} >/dev/null 2>&1; then
        ${docker}/bin/docker create \
          --name ${containerName} \
          --restart=no \
          --device=/dev/net/tun \
          --cap-add=NET_ADMIN \
          -p 127.0.0.1:5901:5901 \
          -p 127.0.0.1:1080:1080 \
          -p 127.0.0.1:8888:8888 \
          -v ${dataVolume} \
          ${image} || true
      fi
      ${docker}/bin/docker start ${containerName} || true
    else
      ${docker}/bin/docker stop ${containerName} || true
    fi
    exit 0
  '';
in
{
  options.orion.easyconnect = {
    enable = lib.mkEnableOption "docker-easyconnect when a campus-only site is reachable";

    campusProbes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "https://kq.xjtu.edu.cn" ];
      example = [ "https://kq.xjtu.edu.cn" ];
      description = ''
        Campus-only HTTPS URLs, with no userinfo. Any one completed probe
        starts the container: TLS plus an HTTP status of 2xx or 3xx, connect
        timeout 3s. Resolving DNS is not enough. A 3xx Location that names a
        different host is not success. If every probe fails, the container
        stops even when campusConnections matches an active SSID. A successful
        probe starts it even when the SSID is not in that list.
      '';
    };

    campusConnections = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "XJTU_STU" ];
      description = ''
        Recorded NetworkManager connection names (the NAME column). They do
        not start or stop the container. campusProbes decides.
      '';
    };

    campusSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "202.117.0.0/16" ];
      description = ''
        Recorded IPv4 CIDRs. They do not start or stop the container.
        Wired campus access is detected by campusProbes.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all probeOk cfg.campusProbes;
        message = "orion.easyconnect.campusProbes must be https URLs without credentials";
      }
    ];

    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.${containerName} = {
      inherit image;
      autoStart = false;
      ports = [
        "127.0.0.1:5901:5901"
        "127.0.0.1:1080:1080"
        "127.0.0.1:8888:8888"
      ];
      volumes = [ dataVolume ];
      devices = [ "/dev/net/tun" ];
      capabilities.NET_ADMIN = true;
      extraOptions = [ "--restart=no" ];
    };

    systemd.services."docker-${containerName}" = {
      wantedBy = lib.mkForce [ ];
      serviceConfig.Restart = lib.mkForce "no";
    };

    networking.networkmanager.dispatcherScripts = [
      {
        source = dispatcher;
        type = "basic";
      }
    ];
  };
}
