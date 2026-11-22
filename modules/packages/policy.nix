{ ... }:
{
  # Baidu's FHS environment and the explicitly enabled fcitx GTK2 immodule
  # still need GTK2. Unstable marks it broken because removal is planned
  # for 27.05, not because these consumers were removed. Keep this one
  # deprecation visible; do not permit unrelated broken packages.
  nixpkgs.config.problems.handlers."gtk+".broken = "warn";
  # yakkhini.dingtalk 9.0.0.261105002 bundles OpenSSL 1.1 (EOL). The package
  # matches the installed client, so this one name is permitted.
  nixpkgs.config.permittedInsecurePackages = [
    "dingtalk-9.0.0.261105002"
  ];

}
