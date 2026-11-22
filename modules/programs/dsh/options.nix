{ lib, ... }:
{
  options.orion.packages.dshPlugins = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "dsh plugin names, including dshmarket. dsh plugin add installs a missing name; dsh-market updates them. Nix does not pin versions.";
  };

}
