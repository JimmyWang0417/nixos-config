{ pkgs }:
let
  # Keep the NUR recipe's Qt/Fcitx wrapper and same-pkgs Wayland capture hook.
  # Only update the official vendor payload and its explicit vulnerability record.
  version = "9.0.0.261118001";
in
pkgs.nur.repos.yakkhini.dingtalk.overrideAttrs (old: {
  inherit version;
  src = pkgs.fetchurl {
    url = "https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Release/com.alibabainc.dingtalk_${version}_amd64.deb";
    hash = "sha256-g0BuCIVPC/mfoXVNa2glqctTylr8bqHFADQciM6hR2k=";
  };
  meta = old.meta // {
    knownVulnerabilities = [
      "The official Linux payload bundles OpenSSL 1.1.1g (EOL). Upgrading DingTalk does not update these vendor libraries."
    ];
  };
})
