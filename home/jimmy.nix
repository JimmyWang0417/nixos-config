# User identity and composition only. Each feature owns its settings and files.
{ config, ... }:
{
  imports = [
    ./editors.nix
    ./xfce.nix
    ./fcitx5
    ./modules/desktop/plasma.nix
    ./modules/desktop/themes.nix
    ./modules/desktop/user-directories.nix
    ./modules/shell/zsh.nix
    ./modules/apps/clash-verge.nix
    ./modules/apps/cc-switch.nix
    ./modules/apps/keepassxc.nix
    ./modules/apps/botmux.nix
    ./modules/apps/openlogi.nix
    ./modules/apps/update-prompts.nix
    ./modules/private
    ./modules/apps/konsole.nix
    ./modules/apps/dolphin.nix
    ./modules/apps/kate.nix
    ./modules/apps/obs-studio.nix
    ./modules/apps/discord.nix
    ./modules/apps/heroic.nix
    ./modules/apps/vlc.nix
    ./modules/apps/btop.nix
  ];
  home.stateVersion = "26.05";
  home.username = "jimmywang0417";
  home.homeDirectory = "/home/${config.home.username}";
}
