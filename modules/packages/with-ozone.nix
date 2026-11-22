{ pkgs }:
  # Wayland flags only expand when NIXOS_OZONE_WL and WAYLAND_DISPLAY are
  # both set, as in the default Plasma Wayland session. Xfce X11
  # does not set WAYLAND_DISPLAY, so the arguments stay empty.
  pkg:
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
    }
