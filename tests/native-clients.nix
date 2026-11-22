{
  pkgs,
  baidu,
  dingtalk,
}:
let
  inherit (pkgs) lib;
  closure = pkgs.closureInfo {
    rootPaths = [
      baidu
      dingtalk
    ];
  };
in
pkgs.runCommand "native-client-runtime-checks"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.binutils
    ];
    CLIENT_DYNAMIC_LOADER = pkgs.stdenv.cc.bintools.dynamicLinker;
    CLIENT_GLIBC = "${lib.getLib pkgs.glibc}";
    CLIENT_GLIBC_OUTPUTS = builtins.toJSON [
      (toString pkgs.glibc)
      (toString pkgs.glibc.bin)
    ];
    CLIENT_CXX_RUNTIME = "${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6";
    CLIENT_CLOSURE_PATHS = "${closure}/store-paths";
    CLIENT_BASH = "${pkgs.bash}/bin/bash";
    BAIDU_ROOT = "${baidu}";
    BAIDU_UNWRAPPED = "${baidu.unwrapped}";
    BAIDU_GTKMM = "${baidu.compatGtkmm}";
    BAIDU_LIBRARY_PATH = lib.makeLibraryPath (baidu.runtimeLibraries ++ [ pkgs.glibc ]);
    FCITX_GTK_ROOT = "${lib.getLib pkgs.fcitx5-gtk}";
    APPINDICATOR_LIBRARY = "${lib.getLib pkgs.libappindicator-gtk3}/lib/libappindicator3.so.1";
    DINGTALK_ROOT = "${dingtalk}";
    DINGTALK_SCREENSHARE = "${dingtalk.dingtalk-wayland-screenshare}/lib/libdingtalkhook.so";
    DINGTALK_KNOWN_VULNERABILITIES = builtins.toJSON dingtalk.meta.knownVulnerabilities;
  }
  ''
    mkdir -p "$out"
    CLIENT_CHECK_REPORT="$out/runtime.json" python3 ${./native-clients.py}
  ''
