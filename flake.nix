{
  description = "Jimmy Wang's NixOS configuration. Current host: orion (Orion-Laptop).";

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

    # Attributes missing or older on nixos-26.05. The system channel stays nixpkgs.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # NUR's master branch is a rename tombstone. Track main, and build the
    # repos against this flake's nixos-26.05 nixpkgs.
    nur.url = "github:nix-community/NUR/main";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    # DedSec, WhiteSur, and Tela. Daily rev bumps stay in this repo.
    nur-packages.url = "github:JimmyWang0417/nur-packages/c5dd6a53d834985520becfa902e2fb0aaa74214b";
    nur-packages.inputs.nixpkgs.follows = "nixpkgs";
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

      # Package expressions that are not in nixpkgs 26.05. Not installed on Orion
      # unless a host module lists them. alder and typora-free-with-plugin are absent.
      overlays.default = import ./overlay.nix;

      packages.x86_64-linux = import ./pkgs {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
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
