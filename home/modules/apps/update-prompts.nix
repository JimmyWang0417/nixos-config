{ lib, pkgs, ... }:
let
  majorMinor = pkg: lib.versions.majorMinor pkg.version;
  androidStudio = pkgs.android-studio;
  androidPatch = lib.versions.patch androidStudio.version;
  # IntelliJ stores the "Check IDE updates" switch in <config>/options/updates.xml.
  # The directory name is the product plus major.minor. Android Studio's folder
  # is sometimes the three-part version, so both names are seeded.
  jbUpdateDirs = [
    "JetBrains/IntelliJIdea${majorMinor pkgs.jetbrains.idea}"
    "JetBrains/PyCharm${majorMinor pkgs.jetbrains.pycharm}"
    "Google/AndroidStudio${majorMinor androidStudio}"
  ] ++ lib.optional (androidPatch != null && androidPatch != "0")
    "Google/AndroidStudio${majorMinor androidStudio}.${androidPatch}";
in {
  # Other in-app "a new version is available" switches. Each key is one the
  # app itself reads. The script only rewrites those keys.
  home.activation.disableInAppUpdatePrompts = lib.hm.dag.entryAfter [ "writeBoundary" "privateAppConfigs" ] ''
    export JB_UPDATE_DIRS=${lib.escapeShellArg (builtins.concatStringsSep ":" jbUpdateDirs)}
    run ${pkgs.python3}/bin/python3 ${../../disable-update-prompts.py}
  '';

}
