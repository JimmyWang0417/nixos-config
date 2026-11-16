# docker-easyconnect runs only when the campus site is not reachable.
# A probe fails on timeout, a non-2xx status, or a redirect to another host.
# DNS alone does not count. A same-host 3xx still counts as success.
# Start only when every probe fails and the container is stopped.
# A successful probe leaves a stopped container stopped.
# A running container stays up when a later unbound probe succeeds: the
# tunnel may be what made the site reachable. Stop when an active
# NetworkManager connection is named in campusConnections, or when a probe
# bound with curl if!<iface> to a physical NIC still succeeds.
# autoStart stays false. The unit is not wanted by the default target.
# The dispatcher uses `docker start` / `docker stop`. No VPN password is stored.
{ config, lib, pkgs, ... }:
let
  cfg = config.orion.easyconnect;
  containerName = "easyconnect";
  image = "hagb/docker-easyconnect:7.6.7";
  dataVolume = "easyconnect-data:/root";
  docker = config.virtualisation.docker.package;
  curl = "${pkgs.curl}/bin/curl";
  tr = "${pkgs.coreutils}/bin/tr";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  ip = "${pkgs.iproute2}/bin/ip";
  grep = "${pkgs.gnugrep}/bin/grep";
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

    # Optional second argument: SO_BINDTODEVICE via curl's if!<iface>, so a
    # tun route cannot satisfy the probe.
    bind_iface="''${2:-}"
    if [ -n "$bind_iface" ]; then
      case "$bind_iface" in
        *[!A-Za-z0-9._-]*)
          exit 1
          ;;
      esac
    fi

    origin="$(host_of "$url")"
    [ -n "$origin" ] || exit 1

    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy

    # --max-redirs 0 keeps the first response. A portal 302 to another host
    # must not be followed into a 200 that would look like success.
    # Connect budget is 3s. --max-time 5 covers DNS plus the status line.
    curl_args=(
      --silent
      --show-error
      --output /dev/null
      --proxy ""
      --noproxy '*'
      --connect-timeout 3
      --max-time 5
      --max-redirs 0
      --proto '=https'
      --proto-redir '=https'
      --write-out '%{http_code}\n%{redirect_url}'
    )
    if [ -n "$bind_iface" ]; then
      curl_args+=(--interface "if!$bind_iface")
    fi
    if ! meta="$(${curl} "''${curl_args[@]}" -- "$url")"; then
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

    # campusSubnets is not consulted. A named campus connection stops the
    # container and never starts it. A physical-NIC probe can also stop it.
    on_named_campus=0
    active_names="$(${nmcli} -g NAME connection show --active 2>/dev/null || true)"
    set -- ${lib.escapeShellArgs cfg.campusConnections}
    for wanted in "$@"; do
      [ -n "$wanted" ] || continue
      if printf '%s\n' "$active_names" | ${grep} -Fxq -- "$wanted"; then
        on_named_campus=1
        break
      fi
    done

    if [ "$on_named_campus" -eq 1 ]; then
      ${docker}/bin/docker stop ${containerName} || true
      exit 0
    fi

    # Already running: an unbound probe can succeed through the tunnel.
    # Stop only if a probe bound to a physical NIC still succeeds.
    state="$(${docker}/bin/docker inspect -f '{{.State.Running}}' ${containerName} 2>/dev/null || true)"
    if [ "$state" = "true" ]; then
      ifaces=""
      add_iface() {
        case "$1" in
          ""|lo|lo[0-9]*|tun[0-9]*|tap[0-9]*|wg[0-9]*|wg-*|docker[0-9]*|br-*|veth*|virbr*|ppp[0-9]*|vpn[0-9]*|tailscale[0-9]*|zt[0-9]*|zth*|sit[0-9]*|ifb[0-9]*|dummy[0-9]*|vboxnet*|vnet*|nm-*|ecs*|ssl[0-9]*|ipsec*|awg[0-9]*|wireguard*|podman*|cni*|flannel*|cali*|vxlan*|gre[0-9]*|gretap*|erspan*|geneve*|macvlan*|macvtap*|ipvlan*)
            return 0
            ;;
          *[!A-Za-z0-9._-]*)
            return 0
            ;;
        esac
        case "
$ifaces
" in
          *"
$1
"*) return 0 ;;
        esac
        ifaces="$ifaces
$1"
      }
      take_default() {
        local routes line dev prev tok
        routes="$(${ip} "$1" route show default 2>/dev/null || true)"
        [ -n "$routes" ] || return 0
        while IFS= read -r line; do
          [ -n "$line" ] || continue
          dev=""
          prev=""
          for tok in $line; do
            if [ "$prev" = "dev" ]; then
              dev="$tok"
            fi
            prev="$tok"
          done
          add_iface "$dev"
        done <<< "$routes"
      }
      take_default -4
      take_default -6
      rows="$(${nmcli} -t -f DEVICE,TYPE,STATE device status 2>/dev/null || true)"
      if [ -n "$rows" ]; then
        while IFS=: read -r dev typ devstate _; do
          case "$typ" in
            wifi|ethernet) ;;
            *) continue ;;
          esac
          case "$devstate" in
            connected*) ;;
            *) continue ;;
          esac
          add_iface "$dev"
        done <<< "$rows"
      fi
      while IFS= read -r dev; do
        [ -n "$dev" ] || continue
        set -- ${lib.escapeShellArgs cfg.campusProbes}
        for url in "$@"; do
          [ -n "$url" ] || continue
          if ${probe} "$url" "$dev"; then
            ${docker}/bin/docker stop ${containerName} || true
            exit 0
          fi
        done
      done <<< "$ifaces"
      exit 0
    fi

    # Stopped or absent. Start only when every probe fails.
    probe_ok=0
    saw_probe=0
    set -- ${lib.escapeShellArgs cfg.campusProbes}
    for url in "$@"; do
      [ -n "$url" ] || continue
      saw_probe=1
      if ${probe} "$url"; then
        probe_ok=1
        break
      fi
    done

    if [ "$saw_probe" -eq 0 ] || [ "$probe_ok" -eq 1 ]; then
      exit 0
    fi

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
    exit 0
  '';
in
{
  options.orion.easyconnect = {
    enable = lib.mkEnableOption "docker-easyconnect when the campus-only site is unreachable";

    campusProbes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "https://kq.xjtu.edu.cn" ];
      example = [ "https://kq.xjtu.edu.cn" ];
      description = ''
        Campus-only HTTPS URLs, with no userinfo. A probe fails on timeout,
        a non-2xx status, or a 3xx Location that names a different host.
        TLS and an HTTP status of 2xx, or 3xx that stays on the same host,
        is success. The connect timeout is 3 seconds. Resolving DNS is not
        enough.         While the container is stopped, every probe failing starts
        it, and any success leaves it stopped. A later unbound success
        does not stop a container that is already running. A probe bound
        to a physical NIC can.
      '';
    };

    campusConnections = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "XJTU_STU" ];
      description = ''
        NetworkManager connection names (the NAME column). If any active
        connection has one of these names, the container is stopped and is
        not started. These names do not start it. A probe that succeeds
        through the tunnel does not keep the container running once one of
        these connections is active.
      '';
    };

    campusSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "202.117.0.0/16" ];
      description = ''
        Recorded IPv4 CIDRs. They do not start or stop the container.
        Wired campus access is a probe bound to the physical NIC.
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
