{ ... }: {
  imports = [
    ./boot.nix
    ./locale.nix
    ./editor.nix
    ./users.nix
    ./nix-settings.nix
    ./nix-download.nix
    ./nix-storage
    ./secrets.nix
    ./private-configs.nix
  ];
}
