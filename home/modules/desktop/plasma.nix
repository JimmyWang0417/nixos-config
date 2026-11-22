{ lib, pkgs, inputs, osConfig, ... }:
let
  whitesur = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.whitesur-kde;
  layout = {
    "plasma-org.kde.plasma.desktop-appletsrc" = pkgs.replaceVars ../../plasma/plasma-org.kde.plasma.desktop-appletsrc {
      whitesurWallpaper = "${whitesur}/share/wallpapers/WhiteSur/contents/images/3840x2160.jpg";
    };
    "plasmashellrc" = pkgs.replaceVars ../../plasma/plasmashellrc {
      plasmaShells = "${pkgs.kdePackages.plasma-desktop}/share/plasma/shells";
    };
    "plasmarc" = ../../plasma/plasmarc;
    "kwinrc" = pkgs.replaceVars ../../plasma/kwinrc {
      fcitxDesktop = "${osConfig.i18n.inputMethod.package}/share/applications/org.fcitx.Fcitx5.desktop";
    };
    "kdeglobals" = ../../plasma/kdeglobals;
    "plasma-localerc" = ../../plasma/plasma-localerc;
    "kxkbrc" = ../../plasma/kxkbrc;
    "kscreenlockerrc" = ../../plasma/kscreenlockerrc;
    "kcminputrc" = ../../plasma/kcminputrc;
    "kactivitymanagerdrc" = ../../plasma/kactivitymanagerdrc;
    "kwinoutputconfig.json" = ../../plasma/kwinoutputconfig.json;
  };
  installLayout = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (name: src: ''
      run ${pkgs.coreutils}/bin/install -Dm644 ${src} "$HOME/.config/${name}"
      run ${pkgs.coreutils}/bin/chmod u+w "$HOME/.config/${name}"
    '')
    layout);
in {
  home.activation.plasmaLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] installLayout;
}
