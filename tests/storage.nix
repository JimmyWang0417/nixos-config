let
  flake = builtins.getFlake (toString ../.);
  system = flake.nixosConfigurations.orion;
  config = system.config;
  daemon = config.systemd.services.nix-daemon;
  optimiser = config.systemd.services.nix-optimise;
  runtimeConfig = "/run/nix-adaptive-gc/settings.conf";
  checks = {
    storageEnabled = config.orion.nix.storage.enable;
    existingRetention =
      config.nix.gc.automatic
      && config.nix.gc.dates == [ "weekly" ]
      && config.nix.gc.options == "--delete-older-than 30d"
      && config.nix.gc.persistent;
    bootMenuLimitPreserved = config.boot.loader.grub.configurationLimit == 20;
    optionalRuntimeInclude = system.pkgs.lib.hasInfix "!include ${runtimeConfig}" config.nix.extraOptions;
    noStaticThresholds = !(config.nix.settings ? min-free) && !(config.nix.settings ? max-free);
    daemonPreparesBeforeStartup =
      system.pkgs.lib.hasInfix "adaptive-gc.py" daemon.preStart
      && system.pkgs.lib.hasInfix "--store /nix/store" daemon.preStart
      && system.pkgs.lib.hasInfix "--output ${runtimeConfig}" daemon.preStart;
    runtimeDirectory =
      builtins.elem "nix-adaptive-gc" daemon.serviceConfig.RuntimeDirectory
      && daemon.serviceConfig.RuntimeDirectoryMode == "0755";
    persistentWeeklyOptimisation =
      config.nix.optimise.automatic
      && config.nix.optimise.dates == [ "Mon *-*-* 04:00:00" ]
      && config.nix.optimise.persistent;
    noInsertionTimeOptimisation = !config.nix.settings.auto-optimise-store;
    upstreamIdleAndACPolicy =
      optimiser.unitConfig.ConditionACPower
      && optimiser.serviceConfig.CPUSchedulingPolicy == "idle"
      && optimiser.serviceConfig.IOSchedulingClass == "idle";
  };
  failures = builtins.filter (name: !checks.${name}) (builtins.attrNames checks);
in
if failures != [ ] then
  throw "Storage maintenance regression: ${builtins.concatStringsSep ", " failures}"
else
  {
    inherit checks runtimeConfig;
    daemonPreStart = daemon.preStart;
  }
