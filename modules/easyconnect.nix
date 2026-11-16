# docker-easyconnect follows the current NetworkManager connection.
# An empty campusConnections and campusSubnets list does not start the container.
# The OCI unit is not wanted by the default target; the dispatcher uses
# `docker start` / `docker stop`. No VPN password is stored here.
{ config, lib, pkgs, ... }:
let
  cfg = config.orion.easyconnect;
  containerName = "easyconnect";
  image = "hagb/docker-easyconnect:7.6.7";
  dataVolume = "easyconnect-data:/root";
  docker = config.virtualisation.docker.package;
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  campusConnections = lib.concatStringsSep "\n" cfg.campusConnections;
  campusSubnets = lib.concatStringsSep "\n" cfg.campusSubnets;
  subnetCheck = pkgs.writeText "easyconnect-subnet-check.py" ''
    import ipaddress, subprocess, sys
    nets = []
    for line in sys.stdin:
        line = line.strip()
        if line:
            nets.append(ipaddress.ip_network(line, strict=False))
    if not nets:
        sys.exit(1)
    out = subprocess.check_output(
        ["${pkgs.iproute2}/bin/ip", "-4", "-o", "addr", "show", "scope", "global"],
        text=True,
    )
    for line in out.splitlines():
        for part in line.split():
            if "/" in part and part[0].isdigit():
                ip = ipaddress.ip_interface(part).ip
                if any(ip in net for net in nets):
                    sys.exit(0)
    sys.exit(1)
  '';
  dispatcher = pkgs.writeShellScript "easyconnect-nm-dispatcher" ''
    action="''${2:-}"
    case "$action" in
      up|down|vpn-up|vpn-down|connectivity-change|dhcp4-change|dhcp6-change) ;;
      *) exit 0 ;;
    esac

    campus_connections=${lib.escapeShellArg campusConnections}
    campus_subnets=${lib.escapeShellArg campusSubnets}
    if [ -z "$campus_connections" ] && [ -z "$campus_subnets" ]; then
      exit 0
    fi

    on_campus=0
    active_names="$(${nmcli} -g NAME connection show --active 2>/dev/null || true)"
    rest="$campus_connections"
    while [ -n "$rest" ]; do
      wanted="''${rest%%$'\n'*}"
      case "$rest" in
        *$'\n'*) rest="''${rest#*$'\n'}" ;;
        *) rest="" ;;
      esac
      [ -z "$wanted" ] && continue
      if printf '%s\n' "$active_names" | ${pkgs.gnugrep}/bin/grep -Fxq -- "$wanted"; then
        on_campus=1
      fi
    done

    if [ -n "$campus_subnets" ] && printf '%s\n' "$campus_subnets" | ${pkgs.python3}/bin/python3 ${subnetCheck}; then
      on_campus=1
    fi

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
    enable = lib.mkEnableOption "docker-easyconnect when the current network is campus";

    campusConnections = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "XJTU_STU" ];
      description = ''
        NetworkManager connection names (the NAME column, which is the
        profile id / SSID for these Wi-Fi profiles). An active connection
        whose name is in this list starts the container.
      '';
    };

    campusSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "202.117.0.0/16" ];
      description = ''
        IPv4 CIDRs. A global address on this host inside any of them counts
        as campus, including Ethernet. An empty list matches connection
        names only.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
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
