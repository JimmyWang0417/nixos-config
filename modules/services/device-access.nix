{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Same derivation listed on orion.packages.unstable.
  openlogi = lib.findFirst (pkg: (pkg.pname or "") == "openlogi") null config.orion.packages.unstable;
in
{
  # The OpenRGB window is the client. The upstream unit stays off, the same
  # as the machine. These rules are what let that window open the devices.
  # openlogi is the same derivation as the orion.packages.unstable entry.
  # Its udev rules ship with that package. logiops is not installed and
  # services.logiops stays unset. There is no logid.cfg.
  # programs.openlogi.enable does not start the agent.
  services.udev.packages = [
    pkgs.openrgb
  ]
  ++ lib.optional (openlogi != null) openlogi;
  boot.kernelModules = [
    "i2c-dev"
    "i2c-i801"
  ];

}
