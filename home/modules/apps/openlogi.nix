{ lib, pkgs, ... }:
let
  openlogi = pkgs.openlogi;
in
{
  systemd.user.services.openlogi-agent = {
    Unit = {
      Description = "OpenLogi background agent (Logitech HID++ device control)";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = lib.getExe' openlogi "openlogi-agent";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
