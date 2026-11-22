{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  autostartDesktop = name: text: "${pkgs.writeTextDir name text}/${name}";
  ccSwitch = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.cc-switch;
in
{
  xdg.autostart.enable = true;
  xdg.autostart.entries = [
    (autostartDesktop "cc-switch.desktop" ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=CC Switch
      Comment=All-in-One Assistant for Claude Code, Codex & Gemini CLI
      Exec=${lib.getExe ccSwitch}
      StartupNotify=false
      Terminal=false
      X-GNOME-Autostart-enabled=true
    '')
  ];
}
