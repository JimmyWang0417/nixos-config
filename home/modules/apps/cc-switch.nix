{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  autostartDesktop = name: text: "${pkgs.writeTextDir name text}/${name}";
  cfg = osConfig.orion.programs.ccSwitch;
in
lib.mkIf cfg.enable {
  xdg.autostart.enable = true;
  xdg.autostart.entries = [
    (autostartDesktop "cc-switch.desktop" ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=CC Switch
      Comment=All-in-One Assistant for Claude Code, Codex & Gemini CLI
      Exec=${lib.getExe cfg.package}
      StartupNotify=false
      Terminal=false
      X-GNOME-Autostart-enabled=true
    '')
  ];
}
