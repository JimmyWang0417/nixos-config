{ lib, pkgs, inputs, ... }:
let
  autostartDesktop = name: text: "${pkgs.writeTextDir name text}/${name}";
in {
  # Clash Verge Rev 2.5.10 (src-tauri/src/core/updater.rs) and 2.4.7
  # (src/hooks/use-update.ts) both read verge.yaml auto_check_update.
  # false skips the startup install dialog, the update splash, and the
  # silent updater. The NixOS module has no switch for this. Only this
  # key is rewritten; TUN, ports, and the rest of the file stay as they are.
  home.activation.clashVergeNoUpdateCheck = lib.hm.dag.entryAfter [ "writeBoundary" "privateAppConfigs" ] ''
    verge="$HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev/verge.yaml"
    run ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$verge")"
    run ${pkgs.python3}/bin/python3 - "$verge" <<'PY'
    import pathlib, sys
    path = pathlib.Path(sys.argv[1])
    text = path.read_text() if path.exists() else ""
    lines = text.splitlines()
    found = False
    out = []
    for line in lines:
        if line.startswith("auto_check_update:"):
            out.append("auto_check_update: false")
            found = True
        else:
            out.append(line)
    if not found:
        out.append("auto_check_update: false")
    new = "\n".join(out)
    if text.endswith("\n") or text == "":
        new += "\n"
    if not path.exists() or new != text:
        path.write_text(new)
    PY
  '';

  xdg.autostart.enable = true;
  xdg.autostart.entries = [
      (autostartDesktop "clash-verge.desktop" ''
        [Desktop Entry]
        Type=Application
        Version=1.0
        Name=Clash Verge
        Comment=Clash Verge Rev
        Exec=${lib.getExe pkgs.clash-verge-rev}
        StartupNotify=false
        Terminal=false
        X-GNOME-Autostart-enabled=true
      '')
  ];
}
