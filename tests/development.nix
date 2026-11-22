let
  flake = builtins.getFlake (toString ../.);
  system = flake.nixosConfigurations.orion;
  inherit (system) pkgs;
  inherit (pkgs) lib;
  home = system.config.home-manager.users.jimmywang0417;
  hasPackage = expected: builtins.any (p: p.drvPath == expected.drvPath) home.home.packages;
  checks = {
    nhUsesUnstable = home.programs.nh.enable && hasPackage pkgs.nh;
    nhSelectsOrion =
      home.home.sessionVariables.NH_OS_FLAKE
      == "${home.home.homeDirectory}/Git Repositories/nixos-config#orion";
    nativeRetentionPreserved =
      !home.programs.nh.clean.enable
      && system.config.nix.gc.automatic
      && system.config.nix.gc.options == "--delete-older-than 30d";
    cachedProjectEnvironment =
      home.programs.direnv.enable
      && home.programs.direnv.enableZshIntegration
      && home.programs.direnv.nix-direnv.enable
      && hasPackage pkgs.direnv
      &&
        toString home.xdg.configFile."direnv/lib/hm-nix-direnv.sh".source
        == "${home.programs.direnv.nix-direnv.package}/share/nix-direnv/direnvrc";
    projectPermissionRequired = !(home.programs.direnv.config ? whitelist);
    indexWrapperInstalled =
      home.programs.nix-index.enable
      && hasPackage home.programs.nix-index.package
      && !(hasPackage pkgs.nix-index);
    commaInstalled =
      home.programs.nix-index-database.comma.enable
      && builtins.any (p: lib.hasPrefix "comma-with-db-" p.name) home.home.packages;
    missingCommandLookup =
      home.programs.nix-index.enableZshIntegration
      && lib.hasInfix (builtins.unsafeDiscardStringContext "${home.programs.nix-index.package}/etc/profile.d/command-not-found.sh") home.programs.zsh.initContent;
    explicitTypoCorrection = lib.hasInfix "pay-respects zsh --alias --nocnf" home.programs.zsh.initContent;
  };
  failures = builtins.filter (name: !checks.${name}) (builtins.attrNames checks);
in
if failures != [ ] then
  throw "Development integration regression: ${builtins.concatStringsSep ", " failures}"
else
  checks
