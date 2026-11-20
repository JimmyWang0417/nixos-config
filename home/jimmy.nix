{ config, lib, pkgs, inputs, osConfig, ... }:
let
  nurPkgs = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
  whitesur = nurPkgs.whitesur-kde;
  tela = nurPkgs.tela-icon-theme;
  breathWallpapers = nurPkgs.breath-wallpapers;
  endeavourosWallpapers = nurPkgs.endeavouros-wallpapers;
  endeavourosCommunityWallpapers = nurPkgs.endeavouros-community-wallpapers;
  layout = {
    "plasma-org.kde.plasma.desktop-appletsrc" = pkgs.replaceVars ./plasma/plasma-org.kde.plasma.desktop-appletsrc {
      whitesurWallpaper = "${whitesur}/share/wallpapers/WhiteSur/contents/images/3840x2160.jpg";
    };
    "plasmashellrc" = pkgs.replaceVars ./plasma/plasmashellrc {
      plasmaShells = "${pkgs.kdePackages.plasma-desktop}/share/plasma/shells";
    };
    "plasmarc" = ./plasma/plasmarc;
    "kwinrc" = pkgs.replaceVars ./plasma/kwinrc {
      fcitxDesktop = "${osConfig.i18n.inputMethod.package}/share/applications/org.fcitx.Fcitx5.desktop";
    };
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
  imports = [ ./editors.nix ];

  home.stateVersion = "26.05";
  home.username = "jimmywang0417";
  home.homeDirectory = "/home/${config.home.username}";

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
  ] ++ [
    # Tela is the standard-color theme from vinceliuice/Tela-icon-theme.
    # WhiteSur stays the active desktop image.
    # Breath, EndeavourOS, and the EndeavourOS classic/community sets are selectable.
    tela
    whitesur
    breathWallpapers
    endeavourosWallpapers
    endeavourosCommunityWallpapers
  ];

  # Writable copies. plasma-manager cannot express the CPU pie chart,
  # the fixed-length spacer, or the two folder-view containments.
  home.activation.plasmaLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] installLayout;

  # Clash Verge Rev 2.5.10 (src-tauri/src/core/updater.rs) and 2.4.7
  # (src/hooks/use-update.ts) both read verge.yaml auto_check_update.
  # false skips the startup install dialog, the update splash, and the
  # silent updater. The NixOS module has no switch for this. Only this
  # key is rewritten; TUN, ports, and the rest of the file stay as they are.
  home.activation.clashVergeNoUpdateCheck = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    verge="$HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev/verge.yaml"
    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$verge")"
    ${pkgs.python3}/bin/python3 - "$verge" <<'PY'
    import pathlib, sys
    path = pathlib.Path(sys.argv[1])
    text = path.read_text() if path.exists() else ""
    lines = text.splitlines()
    found = False
    out = []
    for line in lines:
        if line.startswith("auto_check_update:"):
            out.append("auto_check_update: false")
            found = True
        else:
            out.append(line)
    if not found:
        out.append("auto_check_update: false")
    new = "\n".join(out)
    if text.endswith("\n") or text == "":
        new += "\n"
    if not path.exists() or new != text:
        path.write_text(new)
    PY
  '';
}
