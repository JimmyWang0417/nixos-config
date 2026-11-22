# Runtime-only restoration; decrypted data never enters a derivation or the store.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.orion.secrets;
  helper = ../../lib/restore-private-archive.py;
  secretUnit = lib.optional config.sops.useSystemdActivation "sops-install-secrets.service";
in
{
  config = lib.mkIf cfg.enable {
    # Keep system parents root-owned; only the private auth directory created
    # by the restore helper belongs to the desktop user.
    systemd.tmpfiles.rules = [ "d /opt/kingsoft 0755 root root -" ];
    systemd.services.orion-private-configs = {
      description = "Initialize encrypted NetworkManager and WPS configuration";
      wantedBy = [ "multi-user.target" ];
      before = [ "NetworkManager.service" ];
      after = [ "local-fs.target" ] ++ secretUnit;
      wants = secretUnit;
      path = [
        pkgs.networkmanager
        config.systemd.package
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
      };
      script = ''
        ${pkgs.python3}/bin/python3 ${helper} \
          --archive ${lib.escapeShellArg config.sops.secrets.nm-connections.path} \
          --root /etc/NetworkManager/system-connections --label nm-connections --flat \
          --allow-suffix .nmconnection
        ${pkgs.python3}/bin/python3 ${helper} \
          --archive ${lib.escapeShellArg config.sops.secrets.wps-license.path} \
          --root /opt/kingsoft/.auth --label wps-license --flat \
          --allow-file license2.dat --owner jimmywang0417
        if systemctl is-active --quiet NetworkManager.service; then
          nmcli connection reload
        fi
      '';
    };

    # Home Manager's private archive step must see secrets before starting the
    # user services that consume them. With activation-script mode, sops is
    # already ordered after users/groups and before regular system services.
    systemd.services.home-manager-jimmywang0417 = {
      after = secretUnit;
      wants = secretUnit;
    };
  };
}
