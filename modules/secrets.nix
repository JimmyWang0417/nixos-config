{ config, lib, ... }:
let
  cfg = config.orion.secrets;
in
{
  options.orion.secrets.enable = lib.mkEnableOption "sops-nix age decryption";

  config = lib.mkIf cfg.enable {
    sops.age.keyFile = "/home/jimmywang0417/.config/sops/age/keys.txt";
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # Each file is one sops binary blob (a tar of that concern). Mode 0400.
    sops.secrets = lib.mapAttrs (
      name: file:
      {
        sopsFile = file;
        format = "binary";
        mode = "0400";
        owner = "jimmywang0417";
        group = "jimmywang0417";
      }
    ) {
      fcitx5-pinyin = ../secrets/fcitx5-pinyin.sops;
      clash-verge = ../secrets/clash-verge.sops;
      anytls-ssh-key = ../secrets/anytls-ssh-key.sops;
      rclone-webdav = ../secrets/rclone-webdav.sops;
      jetbrains-licenses = ../secrets/jetbrains-licenses.sops;
      wps-license = ../secrets/wps-license.sops;
      botmux-bots = ../secrets/botmux-bots.sops;
    nm-connections = ../secrets/nm-connections.sops;
    cc-switch = ../secrets/cc-switch.sops;
    };
  };
}
