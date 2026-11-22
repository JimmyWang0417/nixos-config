let
  flake = builtins.getFlake (toString ../.);
  system = flake.nixosConfigurations.orion;
  config = system.config;
  pkgs = system.pkgs;
  lib = pkgs.lib;
  home = config.home-manager.users.jimmywang0417;
  im = config.i18n.inputMethod.package;
  paths = map toString im.paths;
  containsPackage = package: builtins.elem (toString package) paths;
  gtkInputs = map (package: package.drvPath) pkgs.fcitx5-gtk.buildInputs;
  qtPaths = config.environment.sessionVariables.QT_PLUGIN_PATH;
  codeWrapper = home.programs.vscode.package.preFixup;
  sessionScript = config.environment.etc."xdg/plasma-workspace/env/fcitx5.sh".text;
  checks = {
    fcitxSelected = config.i18n.inputMethod.enable && config.i18n.inputMethod.type == "fcitx5";
    nativeWaylandFrontend = config.i18n.inputMethod.fcitx5.waylandFrontend;
    xwaylandHasXim = config.environment.sessionVariables.XMODIFIERS == "@im=fcitx";
    nativeWaylandHasNoForcedModules =
      builtins.all
        (
          name:
          !(builtins.hasAttr name config.environment.sessionVariables)
          && !(builtins.hasAttr name config.environment.variables)
        )
        [
          "GTK_IM_MODULE"
          "QT_IM_MODULE"
          "SDL_IM_MODULE"
        ];
    gtk2And3CachesEnabled = config.i18n.inputMethod.enableGtk2 && config.i18n.inputMethod.enableGtk3;
    gtk2ModuleCompiled =
      builtins.elem pkgs.gtk2.drvPath gtkInputs
      && !(builtins.elem "-DENABLE_GTK2_IM_MODULE=off" pkgs.fcitx5-gtk.cmakeFlags);
    gtk3And4ModulesCompiled = builtins.all (package: builtins.elem package.drvPath gtkInputs) [
      pkgs.gtk3
      pkgs.gtk4
    ];
    gtkModulesInActualFcitxPackage = containsPackage pkgs.fcitx5-gtk;
    qt5ModuleInActualFcitxPackage = containsPackage pkgs.libsForQt5.fcitx5-qt;
    qt6ModuleInActualFcitxPackage = containsPackage pkgs.qt6Packages.fcitx5-qt;
    bothQtPluginPathsExported =
      builtins.all (prefix: lib.hasInfix (builtins.unsafeDiscardStringContext "${im}/${prefix}") qtPaths)
        [
          pkgs.qt5.qtbase.qtPluginPrefix
          pkgs.qt6.qtbase.qtPluginPrefix
        ];
    gtk4SearchPathPresent =
      builtins.elem "/lib/gtk-4.0" config.environment.profileRelativeSessionVariables.GTK_PATH
      && builtins.elem "/lib/gtk-4.0" config.environment.pathsToLink;
    qt6NativeFallbackOrder = config.environment.sessionVariables.QT_IM_MODULES == "wayland;fcitx;ibus";
    codeUsesNativeWaylandIme =
      lib.hasInfix "--enable-wayland-ime=true" codeWrapper
      && lib.hasInfix "--wayland-text-input-version=3" codeWrapper;
    codeWaylandFlagsAreConditional =
      lib.hasInfix "NIXOS_OZONE_WL:+" codeWrapper && lib.hasInfix "WAYLAND_DISPLAY:+" codeWrapper;
    codeWaylandFlagSwitchEnabled = config.environment.sessionVariables.NIXOS_OZONE_WL == "1";
    kwinStartsFcitx =
      lib.hasInfix
        (builtins.unsafeDiscardStringContext "InputMethod=${im}/share/applications/org.fcitx.Fcitx5.desktop")
        config.environment.etc."xdg/kwinrc".text;
    x11AutostartCoversXfce =
      lib.hasInfix "OnlyShowIn=KDE;XFCE;"
        config.environment.etc."xdg/autostart/org.fcitx.Fcitx5.desktop".text;
    bothDesktopsUseSameSessionPolicy = lib.hasInfix sessionScript config.services.xserver.displayManager.sessionCommands;
    pinyinSelected = lib.hasInfix "DefaultIM=pinyin" (builtins.readFile ../home/fcitx5/profile);
    writablePinyinConfigDeployed = lib.hasInfix "install -Dm644" home.home.activation.fcitxConfiguration.data;
    dictionarySecretWired = lib.hasInfix config.sops.secrets.fcitx5-pinyin.path home.home.activation.fcitxConfiguration.data;
  };
  failures = builtins.filter (name: !checks.${name}) (builtins.attrNames checks);
in
if failures != [ ] then
  throw "Input method regression: ${builtins.concatStringsSep ", " failures}"
else
  {
    inherit checks sessionScript;
  }
