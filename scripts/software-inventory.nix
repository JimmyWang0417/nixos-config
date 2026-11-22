# nix eval --impure --json --no-update-lock-file --file scripts/software-inventory.nix
let
  flake = builtins.getFlake (toString ../.);
  system = flake.nixosConfigurations.orion;
  c = system.config;
  p = system.pkgs;
  h = c.home-manager.users.jimmywang0417;
  u = flake.inputs.nur-packages.packages.${p.stdenv.hostPlatform.system};
  # Match the bootloader module's realGrub/grubEfi selection. system.build.grub
  # is intentionally null for EFI-only hosts whose BIOS device is "nodev".
  grubConfig = c.boot.loader.grub;
  grubPkgs = if grubConfig.forcei686 then p.pkgsi686Linux else p;
  grubBase =
    if grubConfig.zfsSupport then
      grubPkgs.grub2.override {
        zfsSupport = true;
        zfs = grubConfig.zfsPackage;
      }
    else
      grubPkgs.grub2;
  grubConfigured =
    if grubConfig.efiSupport then grubBase.override { efiSupport = true; } else grubBase;
  record =
    scope: pkg:
    assert builtins.isAttrs pkg && (pkg.type or null) == "derivation";
    {
      inherit scope;
      name = pkg.pname or pkg.name;
      packageName = pkg.name;
      version = pkg.version or "";
      homepage = pkg.meta.homepage or "";
      position = pkg.meta.position or "";
      description = pkg.meta.description or "";
    }
    // (if pkg ? installMode then { installMode = pkg.installMode; } else { });
  ark = c.orion.archives.ark.package;
  arkExtras = p.lib.optionalAttrs c.orion.archives.ark.enable (
    builtins.listToAttrs (
      p.lib.imap0 (index: pkg: {
        name = "ark-backend-${toString index}";
        value = pkg;
      }) (ark.archiveBackends or [ ])
    )
    // p.lib.optionalAttrs (ark ? privateLibzip) { ark-libzip = ark.privateLibzip; }
    // {
      ark-sevenzip = p._7zz;
    }
  );
  rangerExtras = p.lib.optionalAttrs h.programs.ranger.enable (
    builtins.listToAttrs (
      p.lib.imap0 (index: pkg: {
        name = "ranger-helper-${toString index}";
        value = pkg;
      }) h.programs.ranger.extraPackages
    )
  );
  cage = c.orion.programs.claudeCage.package;
  cageExtras = p.lib.optionalAttrs c.orion.programs.claudeCage.enable (
    builtins.listToAttrs (
      p.lib.imap0 (index: pkg: {
        name = "cage-helper-${toString index}";
        value = pkg;
      }) cage.runtime.tools
    )
    // {
      cage-qemu = p.qemu;
      cage-firmware = p.OVMF;
    }
  );
  extras = {
    inherit (u)
      typora
      qoder-cn
      trae-cn
      deveco-studio
      docker-easyconnect
      ;
    baidunetdisk = import ../packages/baidunetdisk { pkgs = p; };
    baidu-gtkmm2 = (import ../packages/baidunetdisk { pkgs = p; }).compatGtkmm;
    inherit (p.python3Packages)
      pip
      fastapi
      matplotlib
      pillow
      reportlab
      scikit-learn
      scipy
      seaborn
      black
      ;
    inherit (p)
      gcc
      clang-tools
      efm-langserver
      fcitx5
      fcitx5-gtk
      intel-media-driver
      intel-compute-runtime
      microcode-intel
      mesa
      ;
    # Enabled service/activation tools that need not appear in the user PATH.
    thermald = c.services.thermald.package;
    logrotate = p.logrotate;
    grub-bootloader = grubConfigured;
    # This is sops-nix's installer, not the unrelated standalone `sops` CLI.
    sops-installer = c.sops.package;
    inherit (p) cacert wireless-regdb;
    fcitx5-chinese-addons = p.qt6Packages.fcitx5-chinese-addons;
    fcitx5-configtool = p.qt6Packages.fcitx5-configtool;
    fcitx5-qt = p.qt6Packages.fcitx5-qt;
    fcitx5-qt5 = p.libsForQt5.fcitx5-qt;
  }
  // arkExtras
  // rangerExtras
  // cageExtras;
in
map (record "system") c.environment.systemPackages
++ map (record "home") h.home.packages
++ map (record "font") c.fonts.packages
# hardware.firmware applies buildEnv/compression to its declared packages.
# Inspect declarations so versions survive rather than auditing the wrapper.
++ map (record "firmware") (
  builtins.concatLists (
    map (definition: definition.value) system.options.hardware.firmware.definitionsWithLocations
  )
)
++ map (record "vscode-extension") h.programs.vscode.profiles.default.extensions
++ map (record "hardware") [
  c.boot.kernelPackages.kernel
  c.hardware.nvidia.package
]
++ builtins.attrValues (
  builtins.mapAttrs (attribute: pkg: (record "explicit-extra" pkg) // { inherit attribute; }) extras
)
