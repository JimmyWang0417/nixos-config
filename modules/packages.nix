{ config, lib, pkgs, ... }:
{
  options.orion.packages.unstable = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Packages from nixpkgs-unstable when nixos-26.05 is missing or older.";
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
  };
}
