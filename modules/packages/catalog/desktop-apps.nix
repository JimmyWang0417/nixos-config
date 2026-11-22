{ pkgs, inputs, ... }:
let
  nurPkgs = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
  withOzone = import ../with-ozone.nix { inherit pkgs; };
  qoderPkg = nurPkgs.qoder-cn;
  traePkg = nurPkgs.trae-cn;
in
with pkgs;
[
  keepassxc
  # The user unit lives in the Home Manager application modules. The package is nur-packages botmux.
  nurPkgs.botmux
  # Official farion1231/cc-switch. Autostart stays in Home Manager.
  nurPkgs.cc-switch
  telegram-desktop
  clash-verge-rev
  discord
  obsidian
  # Typora's launcher only forwards static extraFlags. It does not read
  # NIXOS_OZONE_WL. The same conditional flags as Qoder and Trae.
  (withOzone nurPkgs.typora)
  (withOzone qoderPkg)
  (withOzone traePkg)
  # Already adds the Wayland flags when WAYLAND_DISPLAY is set.
  nur.repos.MCSeekeri.workbuddy
  (google-chrome.override { plasmaSupport = true; })
  (microsoft-edge.override { plasmaSupport = true; })
  heroic
  libreoffice-qt
  # The FHS launcher is `baidunetdisk --no-sandbox` and ignores NIXOS_OZONE_WL.
  (withOzone nur.repos.freegoxing.baidunetdisk)
  nur.repos.yakkhini.dingtalk
  nur.repos.novel2430.wpsoffice-365
  # ToDesk the package is installed by services.todesk (todeskd).
]
