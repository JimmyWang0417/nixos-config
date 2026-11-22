{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  autostartDesktop = name: text: "${pkgs.writeTextDir name text}/${name}";
in
{
  xdg.autostart.enable = true;
  xdg.autostart.entries = [
    (autostartDesktop "org.keepassxc.KeePassXC.desktop" ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=KeePassXC
      GenericName=密码管理器
      Exec=${lib.getExe pkgs.keepassxc}
      TryExec=${lib.getExe pkgs.keepassxc}
      Icon=keepassxc
      StartupNotify=false
      Terminal=false
      Categories=Utility;Security;Qt;
      X-GNOME-Autostart-enabled=true
      X-GNOME-Autostart-Delay=2
      X-KDE-autostart-after=panel
    '')
  ];
}
