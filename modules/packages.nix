{ config, lib, pkgs, ... }:
let
  # 0.2.2-rc.1 installs plugins with `dsh plugin --profile <name> add`. There is no
  # `dsh market` command. dsh-market is the separate npm package `dshmarket`.
  # Names only. 插件由 dsh-market 更新，Nix 不钉版本.
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
    discord
    obsidian
    google-chrome
    microsoft-edge
    vscode
    heroic
    libreoffice-qt
    nur.repos.freegoxing.baidunetdisk
    nur.repos.yakkhini.dingtalk
    nur.repos.novel2430.wpsoffice-365
    todesk
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
    logiops
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
  # `dsh plugin add` with no version. Registry specs already in the profile stay,
  # so dsh-market can update them. A Nix link: or file: spec is replaced.
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
        add, remove = [], []
        for name in names:
            spec = deps.get(name, "")
            if not isinstance(spec, str):
                spec = ""
            if spec.startswith("link:") or spec.startswith("file:"):
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
