{ ... }:
{
  # Baidu's FHS environment and the explicitly enabled fcitx GTK2 immodule
  # still need GTK2. Unstable marks it broken because removal is planned
  # for 27.05, not because these consumers were removed. Keep this one
  # deprecation visible; do not permit unrelated broken packages.
  nixpkgs.config.problems.handlers."gtk+".broken = "warn";
  # The official DingTalk payload still bundles OpenSSL 1.1.1g (EOL).
  # Keep the exact-name exception; OpenSSL 3 cannot replace its 1.1 SONAMEs.
  nixpkgs.config.permittedInsecurePackages = [
    "dingtalk-9.0.0.261118001"
  ];

}
