{ config, lib, ... }:
let
  cfg = config.orion.secrets;
in
{
  options.orion.secrets.enable = lib.mkEnableOption "sops-nix age decryption";

  config = lib.mkIf cfg.enable {
    sops.age.keyFile = "/home/jimmywang0417/.config/sops/age/keys.txt";
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    # Ciphertext is added per host later. No secret values live in this module.
  };
}
