let
  flake = builtins.getFlake (toString ../.);
  system = flake.nixosConfigurations.orion;
  config = system.config;
  pkgs = system.pkgs;
  unstable = import flake.inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  stableSource = toString flake.inputs.nixpkgs.outPath;
  unstableSource = toString flake.inputs.nixpkgs-unstable.outPath;
  home = config.home-manager.users.jimmywang0417;
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  followers = [
    "home-manager"
    "nixos-hardware"
    "sops-nix"
    "nur"
    "nur-packages"
    "nix-index-database"
    "treefmt-nix"
    "git-hooks"
  ];
  samePackage = left: right: left.drvPath == right.drvPath;
  installed = config.environment.systemPackages;
  declaredPackages =
    installed
    ++ home.home.packages
    ++ config.fonts.packages
    ++ builtins.concatLists (
      map (definition: definition.value) system.options.hardware.firmware.definitionsWithLocations
    )
    ++ home.programs.vscode.profiles.default.extensions
    ++ [
      config.boot.kernelPackages.kernel
      config.hardware.nvidia.package
    ];
  stableDefinitions = builtins.filter (
    package:
    let
      position = package.meta.position or "";
    in
    builtins.isString position && pkgs.lib.hasPrefix "${stableSource}/" position
  ) declaredPackages;
  present = package: builtins.any (samePackage package) installed;
  nurPkgs = flake.inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
  shellInputs = flake.devShells.x86_64-linux.default.nativeBuildInputs;
  checks = {
    distinctSources = stableSource != unstableSource;
    runtimeUsesUnstable = toString pkgs.path == unstableSource;
    runtimeDoesNotUseStable = toString pkgs.path != stableSource;
    noStablePackageDefinitions = stableDefinitions == [ ];
    inputFollowersUseUnstable = builtins.all (
      name: lock.nodes.${name}.inputs.nixpkgs == [ "nixpkgs-unstable" ]
    ) followers;
    resolvedFollowersUseUnstable = builtins.all (
      name: toString flake.inputs.${name}.inputs.nixpkgs.outPath == unstableSource
    ) followers;
    homeUsesGlobalPackages = config.home-manager.useGlobalPkgs;
    homeEditorUsesUnstable = samePackage home.programs.vscode.package unstable.vscode;
    shellUsesUnstableGit = builtins.any (samePackage unstable.git) shellInputs;
    systemGitUsesUnstable = present unstable.git;
    browserUsesUnstable = samePackage config.programs.firefox.package unstable.firefox;
    desktopUsesUnstable = present unstable.kdePackages.kate;
    ccSwitchUsesNurVariant =
      config.orion.programs.ccSwitch.enable
      && samePackage config.orion.programs.ccSwitch.package nurPkgs.cc-switch-no-quick-panel
      && present nurPkgs.cc-switch-no-quick-panel
      && !present nurPkgs.cc-switch;
    kernelUsesUnstable = samePackage config.boot.kernelPackages.kernel unstable.linuxPackages_6_12.kernel;
    nvidiaUsesUnstable = samePackage config.hardware.nvidia.package unstable.linuxPackages_6_12.nvidiaPackages.stable;
    systemStateVersionPreserved = config.system.stateVersion == "26.05";
    homeStateVersionPreserved = home.home.stateVersion == "26.05";
    defaultPlasmaWayland = config.services.displayManager.defaultSession == "plasma";
    plasmaAndXfceSessionsInstalled =
      builtins.all (name: builtins.elem name config.services.displayManager.sessionData.sessionNames)
        [
          "plasma"
          "xfce"
        ];
    xfceX11Fallback =
      config.services.xserver.desktopManager.xfce.enable
      && !config.services.xserver.desktopManager.xfce.enableWaylandSession;
    xfceInputMethodEnvironment =
      pkgs.lib.hasInfix "export GTK_IM_MODULE=fcitx" config.services.xserver.displayManager.sessionCommands
      && pkgs.lib.hasInfix "export QT_IM_MODULE=fcitx" config.services.xserver.displayManager.sessionCommands;
    xfceInputMethodAutostart =
      pkgs.lib.hasInfix "OnlyShowIn=KDE;XFCE;"
        config.environment.etc."xdg/autostart/org.fcitx.Fcitx5.desktop".text;
    nativeWaylandInputMethod =
      !(config.environment.sessionVariables ? GTK_IM_MODULE)
      && !(config.environment.sessionVariables ? QT_IM_MODULE);
    sddmX11Preserved = !config.services.displayManager.sddm.wayland.enable;
    primeOffloadPreserved =
      config.hardware.nvidia.prime.offload.enable
      && config.hardware.nvidia.prime.offload.enableOffloadCmd
      && !config.hardware.nvidia.prime.sync.enable;
  };
  failures = builtins.filter (name: !checks.${name}) (builtins.attrNames checks);
in
if failures != [ ] then
  throw (
    "Package source regression: ${builtins.concatStringsSep ", " failures}"
    +
      pkgs.lib.optionalString (stableDefinitions != [ ])
        "; stable definitions: ${
          builtins.concatStringsSep ", " (map (package: package.name) stableDefinitions)
        }"
  )
else
  {
    inherit checks stableSource unstableSource;
  }
