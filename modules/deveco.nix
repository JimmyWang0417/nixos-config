# Install DevEco Studio.
#
# nur-packages owns the client, the version, the download, and the assembly.
# This module only installs the package. `nixos-rebuild switch --impure` lets
# that package see this machine; a pure evaluation skips it.
{ inputs, ... }:
let
  deveco = inputs.nur-packages.packages.x86_64-linux.deveco-studio;
in
{
  config =
    if deveco.installMode == "install" then
      {
        environment.systemPackages = [ deveco ];
      }
    else if deveco.installMode == "login" then
      {
        assertions = [
          {
            assertion = false;
            message = deveco.installMessage;
          }
        ];
      }
    else
      {
        warnings = [ deveco.installMessage ];
      };
}
