{ config, lib, pkgs, ... }:
let
  cfg = config.orion.users;
in
{
  options.orion.users.jimmy.enable = lib.mkEnableOption "user jimmywang0417";

  config = lib.mkIf cfg.jimmy.enable {
    users.groups.power = { };
    users.groups.network = { };
    users.groups.networkmanager = { };
    users.groups.docker = { };

    users.users.jimmywang0417 = {
      isNormalUser = true;
      uid = 1000;
      description = "Jimmy Wang";
      extraGroups = [ "wheel" "sys" "network" "networkmanager" "power" "docker" "lp" ];
      shell = pkgs.zsh;
    };

    programs.zsh.enable = true;
  };
}
