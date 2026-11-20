{ config, lib, pkgs, inputs, ... }:
let
  nurPkgs = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
  # Wayland flags only expand when NIXOS_OZONE_WL and WAYLAND_DISPLAY are
  # both set, which is the selectable Plasma Wayland session. plasmax11
  # does not set WAYLAND_DISPLAY, so the arguments stay empty.
  withOzone = pkg:
    let
      bin =
        if pkg ? meta.mainProgram && pkg.meta.mainProgram != null then
          pkg.meta.mainProgram
        else
          pkg.pname;
    in
    pkgs.symlinkJoin {
      name = "${bin}-ozone";
      paths = [ pkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram "$out/bin/${bin}" \
          --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
      '';
    };
  qoderPkg = nurPkgs.qoder-cn;
  traePkg = nurPkgs.trae-cn;
  # 0.2.2-rc.3 still installs community plugins with `dsh plugin add`. There is
  # no `dsh market` command. dsh-market is the separate npm package `dshmarket`.
  # Official web bundles stay inside the harness and are not listed here.
  # Names only; versions stay out of this expression.
  dsh = lib.findFirst
    (pkg: (pkg.pname or "") == "deepseek-harness")
    null
    config.orion.packages.unstable;
in
{
  options.orion.packages.unstable = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Packages from nixpkgs-unstable when nixos-26.05 is missing or older.";
  };

  options.orion.packages.dshPlugins = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "dsh plugin names, including dshmarket. dsh plugin add installs a missing name; dsh-market updates them. Nix does not pin versions.";
  };

  config = {
  nixpkgs.config.allowUnfree = true;
  # Local expressions in pkgs/. Orion does not install them from here.
  nixpkgs.overlays = [
    (import ../overlay.nix)
  ];
  # yakkhini.dingtalk 9.0.0.261105002 bundles OpenSSL 1.1 (EOL). The package
  # matches the installed client, so this one name is permitted.
  nixpkgs.config.permittedInsecurePackages = [
    "dingtalk-9.0.0.261105002"
  ];

  programs.firefox = {
    enable = true;
    languagePacks = [ "zh-CN" ];
  };

  # Plasma sets enablePlasmaBrowserIntegration. The host JSON is installed
  # only once programs.chromium.enable is true. That module covers Chromium
  # and Chrome. Edge reads the same manifest from its own directory.
  programs.chromium.enable = true;
  environment.etc."opt/edge/native-messaging-hosts/org.kde.plasma.browser_integration.json".source =
    "${pkgs.kdePackages.plasma-browser-integration}/etc/opt/chrome/native-messaging-hosts/org.kde.plasma.browser_integration.json";

  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    gh
    wget
    curl
    rsync
    rclone
    unzip
    p7zip
    htop
    btop
    fastfetch
    fzf
    lsd
    neovim
    helix
    micro
    ranger
    nano
    cmake
    gnumake
    gdb
    gfortran
    pkg-config
    ninja
    nodejs
    bubblewrap
    python3
    conda
    jdk
    (python3.withPackages (
      ps: with ps; [
        pip
        fastapi
        matplotlib
        pillow
        reportlab
        scikit-learn
        scipy
        seaborn
      ]
    ))
    vlc
    obs-studio
    keepassxc
    telegram-desktop
    clash-verge-rev
    discord
    obsidian
    # Typora's launcher only forwards static extraFlags. It does not read
    # NIXOS_OZONE_WL. The same conditional flags as Qoder and Trae.
    (withOzone nurPkgs.typora)
    (withOzone qoderPkg)
    (withOzone traePkg)
    # Already adds the Wayland flags when WAYLAND_DISPLAY is set.
    nur.repos.MCSeekeri.workbuddy
    (google-chrome.override { plasmaSupport = true; })
    (microsoft-edge.override { plasmaSupport = true; })
    heroic
    libreoffice-qt
    # The FHS launcher is `baidunetdisk --no-sandbox` and ignores NIXOS_OZONE_WL.
    (withOzone nur.repos.freegoxing.baidunetdisk)
    nur.repos.yakkhini.dingtalk
    nur.repos.novel2430.wpsoffice-365
    # ToDesk the package is installed by services.todesk (todeskd).
    typst
    pandoc
    jetbrains.idea
    jetbrains.pycharm
    btrfs-progs
    compsize
    ntfs3g
    exfatprogs
    dosfstools
    e2fsprogs
    xfsprogs
    cryptsetup
    lvm2
    mdadm
    dmidecode
    usbutils
    pciutils
    powertop
    acpi
    config.boot.kernelPackages.cpupower
    inxi
    alsa-utils
    ffmpeg
    libdvdcss
    mesa-demos
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    openrgb
    mariadb
    nfs-utils
    samba
    papirus-icon-theme
    xdg-utils
    xterm
    udiskie
    pipx
    shfmt
    tokei
    marksman
    bash-language-server
    universal-ctags
  ] ++ config.orion.packages.unstable;

  assertions = [
    {
      assertion = config.orion.packages.dshPlugins == [ ] || dsh != null;
      message = "orion.packages.dshPlugins requires deepseek-harness on orion.packages.unstable.";
    }
  ];

  # Home-manager module, so lib.hm exists. Missing names go through
  # `dsh plugin add` with no version. A dependency whose key and spec are both
  # absent from this list is removed. A saved registry spec that is still listed
  # stays so dsh-market can update it. A Nix link: or file: spec is replaced.
  home-manager.users.jimmywang0417 = { lib, ... }: {
    config = lib.mkIf (config.orion.packages.dshPlugins != [ ] && dsh != null) {
      home.activation.dshPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        export DSH=${dsh}/bin/dsh
        export DSH_PLUGIN_NAMES=${lib.escapeShellArg (builtins.toJSON config.orion.packages.dshPlugins)}
        ${pkgs.python3}/bin/python3 - <<'PY'
        import json, os, pathlib, subprocess
        names = json.loads(os.environ["DSH_PLUGIN_NAMES"])
        root = pathlib.Path(os.environ.get("DSH_HOME") or pathlib.Path.home() / ".dsh")
        manifest_path = root / "profiles" / "web" / "package.json"
        deps = {}
        if manifest_path.exists():
            deps = json.loads(manifest_path.read_text()).get("dependencies") or {}
        wanted = set(names)
        add, remove = [], []
        for key, spec in deps.items():
            if not isinstance(spec, str):
                spec = ""
            if key not in wanted and spec not in wanted:
                remove.append(key)
        for name in names:
            spec = deps.get(name, "")
            if not isinstance(spec, str):
                spec = ""
            # pnpm saves `github:owner/repo` under the package name, not the spec.
            if spec == "" and any(isinstance(value, str) and value == name for value in deps.values()):
                continue
            if spec.startswith("link:") or spec.startswith("file:"):
                if name not in remove:
                    remove.append(name)
                add.append(name)
            elif spec == "":
                add.append(name)
        dsh = os.environ["DSH"]
        if remove:
            subprocess.check_call([dsh, "plugin", "--profile", "web", "remove", *remove])
        if add:
            subprocess.check_call([dsh, "plugin", "--profile", "web", "add", *add])
        PY
      '';
    };
  };
  };
}
