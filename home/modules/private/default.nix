{ lib, pkgs, ... }:
let
  archives = map import [
    ./clash.nix
    ./rclone.nix
    ./jetbrains.nix
    ./botmux.nix
    ./cc-switch.nix
  ];
  restore = archive: ''
    run ${pkgs.python3}/bin/python3 ${../../../lib/restore-private-archive.py} \
      --archive ${lib.escapeShellArg "/run/secrets/${archive.secret}"} \
      --root "$HOME"/${lib.escapeShellArg archive.destination} \
      --label ${lib.escapeShellArg archive.secret} \
      ${lib.optionalString (archive.flat or false) "--flat"} \
      ${
        lib.concatMapStringsSep " " (file: "--allow-file ${lib.escapeShellArg file}") (archive.files or [ ])
      } \
      ${lib.concatMapStringsSep " " (file: "--guard-file ${lib.escapeShellArg file}") (
        archive.guards or [ ]
      )}
  '';
in
{
  # Restore before user services start and before public UI defaults are seeded.
  # Missing or unreadable runtime secrets are reported and safely skipped.
  home.activation.privateAppConfigs =
    lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "writeBoundary" ]
      (lib.concatMapStringsSep "\n" restore archives);
}
