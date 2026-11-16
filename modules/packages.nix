{ config, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

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
    libreoffice
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
  ];
}
