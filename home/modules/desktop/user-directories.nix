{ ... }: {
  xdg.userDirs = {
    # Home Manager writes read-only user-dirs.dirs and enabled=False in
    # user-dirs.conf, so the Chinese UI locale cannot translate these paths.
    enable = true;
    createDirectories = true;
    setSessionVariables = false;
    desktop = "$HOME/Desktop";
    download = "$HOME/Downloads";
    templates = "$HOME/Templates";
    publicShare = "$HOME/Public";
    documents = "$HOME/Documents";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
    # Preserve this machine's mapping to Home, rather than creating ~/Projects.
    # HM 26.05 has a native option; extraConfig keys no longer include XDG_/_DIR.
    projects = "$HOME/";
  };
}
