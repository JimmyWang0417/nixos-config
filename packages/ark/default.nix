{
  pkgs,
  legacyChineseZip ? true,
}:
let
  inherit (pkgs) lib;
  # Ark already requests OpenSSL-enabled libzip for AES ZIP support. Keep that
  # exact variant and patch this private dependency only, never global pkgs.libzip.
  opensslLibzip = pkgs.libzip.override { withOpenssl = true; };
  privateLibzip =
    if legacyChineseZip then
      opensslLibzip.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./libzip-legacy-chinese.patch ];
      })
    else
      opensslLibzip;

  # Ark's CLI plugin looks for "7z", while official Linux 7-Zip installs "7zz".
  # The alias is private to Ark so other applications keep their own selection.
  sevenZipBackend = pkgs.runCommand "ark-7z-backend" { } ''
    mkdir -p "$out/bin"
    ln -s ${lib.getExe pkgs._7zz} "$out/bin/7z"
  '';
  archiveBackends = [
    sevenZipBackend
    pkgs.unrar
    pkgs.unar
    pkgs.zip
    pkgs.unzip
    pkgs.lrzip
    pkgs.lzop
    pkgs.zstd
    pkgs.lz4
  ];
  archiveBackendPath = lib.makeBinPath archiveBackends;
  ark = pkgs.kdePackages.ark.override { libzip = privateLibzip; };
in
ark.overrideAttrs (old: {
  # Extend the existing Qt wrapper rather than replacing Ark's executable,
  # desktop file or D-Bus service: every launch path resolves the same plugins.
  qtWrapperArgs = (old.qtWrapperArgs or [ ]) ++ [
    "--prefix"
    "PATH"
    ":"
    archiveBackendPath
  ];
  passthru = (old.passthru or { }) // {
    inherit
      privateLibzip
      legacyChineseZip
      archiveBackendPath
      archiveBackends
      ;
  };
})
