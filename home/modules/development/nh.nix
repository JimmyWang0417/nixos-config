{ config, ... }:
{
  programs.nh = {
    enable = true;
    # Keep a writable checkout reference; the flake key differs from the hostname.
    osFlake = "${config.home.homeDirectory}/Git Repositories/nixos-config#orion";
    # Native NixOS GC owns the existing 30-day retention and adaptive policy.
    clean.enable = false;
  };
}
