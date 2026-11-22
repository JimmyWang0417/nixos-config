{ pkgs }:
let
  inherit (pkgs) lib;
  runtime = import ./runtime.nix { inherit pkgs; };
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "claude-cage";
  version = "0.1.8";
  src = pkgs.fetchurl {
    url = "https://github.com/Lee-xeo/Claude-Cage/releases/download/v${finalAttrs.version}/Cage-${finalAttrs.version}-linux-amd64.deb";
    hash = "sha256-fraLAN2Uwmw7KzQIwz0eBH6voIoQu2yoyFEYiWNF4Bg=";
  };
  nativeBuildInputs = [
    pkgs.dpkg
    pkgs.autoPatchelfHook
    pkgs.wrapGAppsHook3
  ];
  buildInputs = [
    pkgs.gtk3
    pkgs.webkitgtk_4_1
    pkgs.json-glib
    pkgs.glib
    pkgs.fcitx5-gtk
  ];
  dontUnpack = true;
  dontWrapGApps = true;
  installPhase = ''
    runHook preInstall
    dpkg-deb -x "$src" payload
    mkdir -p "$out/bin" "$out/lib" "$out/share"
    cp -a payload/usr/lib/claude-cage "$out/lib/"
    cp -a payload/usr/share/. "$out/share/"
    ln -s ../lib/claude-cage/cage "$out/bin/claude-cage"
    ln -s ../lib/claude-cage/cage-desktop "$out/bin/cage-desktop"
    substituteInPlace "$out/share/applications/io.github.lee_xeo.Cage.desktop" \
      --replace-fail 'Exec=/usr/bin/cage-desktop' "Exec=$out/bin/cage-desktop"
    runHook postInstall
  '';
  # Keep the backend, desktop executable and bundled Mihomo adjacent: both
  # native programs resolve their siblings through /proc/self/exe/os.Executable.
  preFixup = ''
    for program in cage cage-desktop; do
      wrapProgram "$out/lib/claude-cage/$program" \
        "''${gappsWrapperArgs[@]}" \
        --prefix PATH : ${runtime.path} \
        --prefix GTK_PATH : ${lib.getLib pkgs.fcitx5-gtk}/lib/gtk-3.0 \
        --set-default SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
        --set-default QEMU_SYSTEM_X86_64 ${runtime.qemu}/bin/qemu-system-x86_64
    done
  '';
  passthru = {
    inherit runtime;
    bundledMihomoVersion = "1.19.33";
    tests.runtime = import ../../tests/claude-cage.nix {
      inherit pkgs;
      cage = finalAttrs.finalPackage;
    };
  };
  meta = {
    description = "Official Claude Cage desktop and its persistent Linux virtual-machine environment";
    homepage = "https://github.com/Lee-xeo/Claude-Cage";
    changelog = "https://github.com/Lee-xeo/Claude-Cage/releases/tag/v${finalAttrs.version}";
    license = [
      lib.licenses.mit
      lib.licenses.gpl3Only
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "cage-desktop";
  };
})
