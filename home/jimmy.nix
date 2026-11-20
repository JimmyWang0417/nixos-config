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
  ccSwitch = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.cc-switch;
  openlogi = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.openlogi;
  autostartDesktop = name: text: "${pkgs.writeTextDir name text}/${name}";
  # Android Studio is unfree, so this is the same locked nixpkgs-unstable with that switch on.
  unstableUnfree = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  majorMinor = pkg: lib.versions.majorMinor pkg.version;
  androidStudio = unstableUnfree.android-studio;
  androidPatch = lib.versions.patch androidStudio.version;
  # IntelliJ stores the "Check IDE updates" switch in <config>/options/updates.xml.
  # The directory name is the product plus major.minor. Android Studio's folder
  # is sometimes the three-part version, so both names are seeded.
  jbUpdateDirs = [
    "JetBrains/IntelliJIdea${majorMinor pkgs.jetbrains.idea}"
    "JetBrains/PyCharm${majorMinor pkgs.jetbrains.pycharm}"
    "Google/AndroidStudio${majorMinor androidStudio}"
  ] ++ lib.optional (androidPatch != null && androidPatch != "0")
    "Google/AndroidStudio${majorMinor androidStudio}.${androidPatch}";
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

  # Other in-app "a new version is available" switches. Each key is one the
  # app itself reads. The script only rewrites those keys.
  home.activation.disableInAppUpdatePrompts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export JB_UPDATE_DIRS=${lib.escapeShellArg (builtins.concatStringsSep ":" jbUpdateDirs)}
    ${pkgs.python3}/bin/python3 ${./disable-update-prompts.py}
  '';

  # Apps that actually autostart on this Plasma X11 session.
  # Clash Verge's TUN helper stays programs.clash-verge.serviceMode.
  xdg.autostart = {
    enable = true;
    entries = [
      (autostartDesktop "clash-verge.desktop" ''
        [Desktop Entry]
        Type=Application
        Version=1.0
        Name=Clash Verge
        Comment=Clash Verge Rev
        Exec=${lib.getExe pkgs.clash-verge-rev}
        StartupNotify=false
        Terminal=false
        X-GNOME-Autostart-enabled=true
      '')
      (autostartDesktop "cc-switch.desktop" ''
        [Desktop Entry]
        Type=Application
        Version=1.0
        Name=CC Switch
        Comment=All-in-One Assistant for Claude Code, Codex & Gemini CLI
        Exec=${lib.getExe ccSwitch}
        StartupNotify=false
        Terminal=false
        X-GNOME-Autostart-enabled=true
      '')
      (autostartDesktop "org.keepassxc.KeePassXC.desktop" ''
        [Desktop Entry]
        Type=Application
        Version=1.0
        Name=KeePassXC
        GenericName=密码管理器
        Exec=${lib.getExe pkgs.keepassxc}
        TryExec=${lib.getExe pkgs.keepassxc}
        Icon=keepassxc
        StartupNotify=false
        Terminal=false
        Categories=Utility;Security;Qt;
        X-GNOME-Autostart-enabled=true
        X-GNOME-Autostart-Delay=2
        X-KDE-autostart-after=panel
      '')
    ];
  };

  # Same user units this machine enables. OpenLogi's package and udev rules
  # stay on the host; programs.openlogi.enable does not start the agent.
  systemd.user.services.botmux = {
    Unit = {
      Description = "botmux daemon (IM <-> AI coding CLI bridge)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = [ "BOTMUX_AUTOSTART_UNIT=1" ];
      ExecStart = "${pkgs.writeShellScript "botmux-user-start" ''
        mkdir -p "$HOME/.botmux"
        cd "$HOME/.botmux"
        exec ${lib.getExe nurPkgs.botmux} start
      ''}";
      ExecStop = "${lib.getExe nurPkgs.botmux} stop";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.openlogi-agent = {
    Unit = {
      Description = "OpenLogi background agent (Logitech HID++ device control)";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = lib.getExe' openlogi "openlogi-agent";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
