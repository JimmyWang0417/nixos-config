{
  description = "Multi-host NixOS. First host: Orion-Laptop (HP OMEN 16).";

  inputs = {
    # nixos-26.11 is not published (no branch, channel 404). Track stable.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # nixos-hardware publishes master only.
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # nixos-26.05 has no deepseek-harness attribute. This input supplies only that package.
    nixpkgs-deepseek.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # NUR's master branch is a rename tombstone. Track main, and build the
    # repos against this flake's nixos-26.05 nixpkgs.
    nur.url = "github:nix-community/NUR/main";
    nur.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, home-manager, nixos-hardware, sops-nix, nur, ... }@inputs:
    let
      lib = nixpkgs.lib;
      mkHost = name: spec:
        lib.nixosSystem {
          system = spec.system;
          specialArgs = {
            inherit inputs;
            hostName = spec.hostName;
            host = spec // { inherit name; };
          };
          modules = [
            ./modules
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            nur.modules.nixos.default
          ] ++ spec.modules;
        };
    in
    {
      nixosConfigurations = lib.mapAttrs mkHost {
        orion = {
          system = "x86_64-linux";
          hostName = "Orion-Laptop";
          modules = [ ./hosts/orion ];
        };
      };

      devShells.x86_64-linux.default =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        pkgs.mkShell {
          packages = with pkgs; [ git ];
        };
    };
}
