{ pkgs }:
let
  inherit (pkgs) lib;
  version = "8.9.7";
  src = pkgs.fetchurl {
    # Official Linux download API: /disk/cmsdata?do=client&adCode=1.
    url = "https://pkg-ant.baidu.com/issue/netdisk/LinuxGuanjia/${version}/baidunetdisk_${version}_amd64.deb";
    hash = "sha256-bApd9P6Q9/GqXgfppwROPk0bbMqnvqvcH3+cwl+jsxw=";
  };
  compatGtkmm = pkgs.callPackage ./gtkmm2.nix { };
  unwrapped = pkgs.stdenvNoCC.mkDerivation {
    pname = "baidunetdisk-unwrapped";
    inherit version src;
    nativeBuildInputs = [ pkgs.dpkg ];
    dontUnpack = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      dpkg-deb -x "$src" deb-root
      mkdir -p "$out/opt/baidunetdisk"
      cp -a deb-root/opt/baidunetdisk/. "$out/opt/baidunetdisk/"
      runHook postInstall
    '';
  };
  runtimeLibraries = with pkgs; [
    compatGtkmm
    atkmm
    glibmm_2_4
    cairomm_1_0
    pangomm_1_4
    libsigcxx_2_0
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fcitx5-gtk
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk2
    gtk3
    libappindicator-gtk3
    libdbusmenu
    libdrm
    libgbm
    libglvnd
    libpulseaudio
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxtst
    libxi
    libxcursor
    libxt
    libxinerama
    libxrender
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    udev
    vulkan-loader
    wayland
    xdg-utils
  ];
  desktopItem = pkgs.makeDesktopItem {
    name = "baidunetdisk";
    desktopName = "Baidu Netdisk";
    exec = "baidunetdisk %U";
    terminal = false;
    icon = "baidunetdisk";
    startupWMClass = "baidunetdisk";
    comment = "Official Baidu Netdisk desktop client";
    mimeTypes = [ "x-scheme-handler/baiduyunguanjia" ];
    categories = [ "Network" ];
    extraConfig = {
      "Name[zh_CN]" = "百度网盘";
      "Name[zh_TW]" = "百度網盤";
      "Comment[zh_CN]" = "百度网盘";
      "Comment[zh_TW]" = "百度網盤";
    };
  };
in
pkgs.buildFHSEnv {
  pname = "baidunetdisk";
  inherit version src;
  executableName = "baidunetdisk";
  targetPkgs = _: runtimeLibraries;
  multiPkgs = _: [ ];
  runScript = pkgs.writeShellScript "baidunetdisk-launcher" ''
    export LD_LIBRARY_PATH="${unwrapped}/opt/baidunetdisk''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    # This is also the vendor's official .desktop Exec flag. The outer FHS
    # environment does not imply that Chromium's own sandbox is enabled.
    exec ${unwrapped}/opt/baidunetdisk/baidunetdisk --no-sandbox "$@"
  '';
  extraInstallCommands = ''
    mkdir -p "$out/share/applications"
    cp ${desktopItem}/share/applications/*.desktop "$out/share/applications/"
    install -Dm644 ${unwrapped}/opt/baidunetdisk/baidunetdisk.svg "$out/share/icons/hicolor/scalable/apps/baidunetdisk.svg"
  '';
  passthru = {
    inherit unwrapped compatGtkmm runtimeLibraries;
    officialDownloadApi = "https://pan.baidu.com/disk/cmsdata?do=client&adCode=1";
    sourcePolicy = "Private GTKmm 2.24.5 source build; every toolchain and runtime dependency comes from caller pkgs. No older nixpkgs import.";
  };
  meta = {
    description = "Official Baidu Netdisk Linux desktop client";
    homepage = "https://pan.baidu.com/";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "baidunetdisk";
  };
}
