let
  flake = builtins.getFlake (toString ../.);
  system = flake.nixosConfigurations.orion;
  inherit (system.pkgs) lib;
  home = system.config.home-manager.users.jimmywang0417;
  expected = {
    DESKTOP = "$HOME/Desktop";
    DOCUMENTS = "$HOME/Documents";
    DOWNLOAD = "$HOME/Downloads";
    MUSIC = "$HOME/Music";
    PICTURES = "$HOME/Pictures";
    PROJECTS = "$HOME/";
    PUBLICSHARE = "$HOME/Public";
    TEMPLATES = "$HOME/Templates";
    VIDEOS = "$HOME/Videos";
  };
  expectedLines = lib.mapAttrsToList (key: value: ''XDG_${key}_DIR="${value}"'') expected;
  generated = home.xdg.configFile."user-dirs.dirs".text;
  actualLines = builtins.filter (line: line != "") (lib.splitString "\n" generated);
  checks = {
    completeEnglishMappings =
      lib.sort builtins.lessThan actualLines == lib.sort builtins.lessThan expectedLines;
    nativeUpdaterDisabled = home.xdg.configFile."user-dirs.conf".text == "enabled=False";
    projectsMapsToHome =
      home.xdg.userDirs.projects == "$HOME/"
      && !lib.hasInfix "$HOME/Projects" home.home.activation.createXdgUserDirectories.data;
    noLegacyExtraConfigKey = !lib.hasInfix "XDG_XDG_" generated;
    chineseLocalePreserved = system.config.i18n.defaultLocale == "zh_CN.UTF-8";
    queryFileIsAuthoritative = !home.xdg.userDirs.setSessionVariables;
    existingLocaleMarkerPreserved = !(home.xdg.configFile ? "user-dirs.locale");
    personalPlacesRemainWritable =
      !(home.xdg.dataFile ? "user-places.xbel") && !(home.home.file ? ".local/share/user-places.xbel");
  };
  failures = builtins.filter (name: !checks.${name}) (builtins.attrNames checks);
in
if failures != [ ] then
  throw "User directory regression: ${builtins.concatStringsSep ", " failures}"
else
  { inherit checks generated; }
