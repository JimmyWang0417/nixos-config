# Account from getent. The password is not imported.
# Live groups: jimmywang0417, sys, network, power, docker, lp, wheel.
# Home mode on the host is 0700, which is the NixOS default for a normal user.
{ pkgs, ... }:
{
  users.mutableUsers = true;

  users.groups.jimmywang0417.gid = 1000;
  users.groups.sys = { };
  users.groups.network = { };
  users.groups.power = { };

  users.users.jimmywang0417 = {
    isNormalUser = true;
    uid = 1000;
    group = "jimmywang0417";
    description = "Jimmy Wang";
    extraGroups = [
      "wheel"
      "sys"
      "network"
      "power"
      "docker"
      "lp"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
}
