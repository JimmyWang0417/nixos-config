{ lib, pkgs, inputs, ... }:
let nurPkgs = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
in {
  systemd.user.services.botmux = {
    Unit = {
      Description = "botmux daemon (IM <-> AI coding CLI bridge)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = [ "BOTMUX_AUTOSTART_UNIT=1" ];
      ExecStart = "${pkgs.writeShellScript "botmux-user-start" ''
        mkdir -p "$HOME/.botmux"
        cd "$HOME/.botmux"
        exec ${lib.getExe nurPkgs.botmux} start
      ''}";
      ExecStop = "${lib.getExe nurPkgs.botmux} stop";
    };
    Install.WantedBy = [ "default.target" ];
  };

}
