{ pkgs, ark }:
pkgs.runCommand "ark-archive-behavior"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    ARK_BIN = "${ark}/bin/ark";
    ARK_PLUGIN_DIR = "${ark}/lib/qt-6/plugins/kerfuffle";
    ARK_PRIVATE_LIBZIP = "${pkgs.lib.getLib ark.privateLibzip}/lib/libzip.so";
    ARK_MIME_DATA_DIR = "${pkgs.shared-mime-info}/share";
    SEVENZIP_BIN = "${pkgs._7zz}/bin/7zz";
  }
  ''
    python3 ${./ark.py}
    touch "$out"
  ''
