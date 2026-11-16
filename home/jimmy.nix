{ config, lib, pkgs, ... }:
let
  layout = {
    "plasma-org.kde.plasma.desktop-appletsrc" = ./plasma/plasma-org.kde.plasma.desktop-appletsrc;
    "plasmashellrc" = ./plasma/plasmashellrc;
    "plasmarc" = ./plasma/plasmarc;
    "kwinrc" = ./plasma/kwinrc;
    "kdeglobals" = ./plasma/kdeglobals;
    "plasma-localerc" = ./plasma/plasma-localerc;
    "kxkbrc" = ./plasma/kxkbrc;
    "kscreenlockerrc" = ./plasma/kscreenlockerrc;
    "kcminputrc" = ./plasma/kcminputrc;
    "kactivitymanagerdrc" = ./plasma/kactivitymanagerdrc;
    "kwinoutputconfig.json" = ./plasma/kwinoutputconfig.json;
    "fcitx5/profile" = ./fcitx5/profile;
    "fcitx5/conf/pinyin.conf" = ./fcitx5/conf/pinyin.conf;
  };
  installLayout = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (name: src: ''
      ${pkgs.coreutils}/bin/install -Dm644 ${src} "$HOME/.config/${name}"
      ${pkgs.coreutils}/bin/chmod u+w "$HOME/.config/${name}"
    '')
    layout);
in
{
  home.stateVersion = "26.05";
  home.username = "jimmywang0417";
  home.homeDirectory = "/home/jimmywang0417";

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "$HOME/Desktop";
    download = "$HOME/Downloads";
    templates = "$HOME/Templates";
    publicShare = "$HOME/Public";
    documents = "$HOME/Documents";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
    extraConfig.XDG_PROJECTS_DIR = "$HOME/";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
    shellAliases = {
      ls = "lsd";
      pon = "export http_proxy=http://127.0.0.1:10808 https_proxy=http://127.0.0.1:10808 HTTP_PROXY=http://127.0.0.1:10808 HTTPS_PROXY=http://127.0.0.1:10808";
      poff = "unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY";
    };
    initContent = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      eval "$(${pkgs.pay-respects}/bin/pay-respects zsh)"
    '';
  };

  home.packages = with pkgs; [
    lsd
    pay-respects
    zsh-powerlevel10k
    tela-icon-theme
  ];

  # Writable copies. plasma-manager cannot express the CPU pie chart,
  # the fixed-length spacer, or the two folder-view containments.
  home.activation.plasmaLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] installLayout;
}
