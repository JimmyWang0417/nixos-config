{ ... }:
{
  imports = [
    ./options.nix
    ./runtime.nix
  ];

  # dsh-market updates registry plugins. The catalog records names, not versions.
  orion.packages.dshPlugins = import ./plugins;
}
