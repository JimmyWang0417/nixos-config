{ config, lib, ... }:
{
  imports = [
    ./gc.nix
    ./adaptive-gc.nix
    ./optimise.nix
  ];

  options.orion.nix.storage.enable = lib.mkEnableOption "Nix storage maintenance" // {
    default = config.orion.nix.enable;
  };
}
