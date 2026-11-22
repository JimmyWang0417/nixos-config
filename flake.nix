{
  description = "Jimmy Wang's NixOS configuration. Current host: orion (Orion-Laptop).";

  # Binary caches only. Flake inputs stay on their pinned GitHub revisions.
  # Keep this list identical to orion.nix.chinaMirrors.substituters.
  nixConfig = {
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  inputs = {
    # Stable is retained as an explicit opt-in source only. On 2026-11-22
    # nixos-26.11 is not published; move this to it once the branch exists.
    # Runtime packages and NixOS modules all use nixpkgs-unstable below.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs-unstable";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # nixos-hardware publishes master only.
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs-unstable";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # Single active source for the complete system and all applications.
    # nixos-unstable passes NixOS channel tests before advancing.
    # Upstream stable application releases are packaged on this rolling branch;
    # choosing unstable does not force applications onto upstream prereleases.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # NUR's master branch is a rename tombstone. Track main, and build the
    # repos against the same unstable package set as the system.
    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # DedSec, Tela, WhiteSur, Typora, Qoder CN, Trae CN, DevEco, and CC Switch.
    # Daily rev bumps stay in nur-packages.
    nur-packages.url = "github:JimmyWang0417/nur-packages";
    nur-packages.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      sops-nix,
      nur,
      ...
    }@inputs:
    let
      lib = inputs.nixpkgs-unstable.lib;
      toolsPkgs = import inputs.nixpkgs-unstable { system = "x86_64-linux"; };
      quality = import ./nix/quality.nix {
        inherit inputs self;
        pkgs = toolsPkgs;
      };
      mkHost =
        name: spec:
        lib.nixosSystem {
          system = spec.system;
          specialArgs = {
            inherit inputs;
            # Explicit fallback interface; unused unless a module requests it.
            # Do not alias this to pkgs: that would silently restore old apps.
            pkgsStable = import nixpkgs {
              system = spec.system;
              config.allowUnfree = true;
            };
            hostName = spec.hostName;
            host = spec // {
              inherit name;
            };
          };
          modules = [
            ./modules
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            nur.modules.nixos.default
          ]
          ++ spec.modules;
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

      formatter.x86_64-linux = quality.formatter;
      checks.x86_64-linux = quality.checks // {
        claude-cage-runtime =
          self.nixosConfigurations.orion.config.orion.programs.claudeCage.package.tests.runtime;
        node-xdg = import ./tests/node-xdg-check.nix { pkgs = toolsPkgs; };
        native-clients = import ./tests/native-clients.nix {
          pkgs = self.nixosConfigurations.orion.pkgs;
          baidu = import ./packages/baidunetdisk { pkgs = self.nixosConfigurations.orion.pkgs; };
          dingtalk = import ./packages/dingtalk { pkgs = self.nixosConfigurations.orion.pkgs; };
        };
        neovim-commands = import ./tests/neovim.nix { pkgs = toolsPkgs; };
        ranger-previews = import ./tests/ranger.nix { pkgs = toolsPkgs; };
        ark-archives = import ./tests/ark.nix {
          pkgs = toolsPkgs;
          ark = self.nixosConfigurations.orion.config.orion.archives.ark.package;
        };
      };

      devShells.x86_64-linux.default = toolsPkgs.mkShell {
        packages = [
          toolsPkgs.git
          toolsPkgs.python3
        ]
        ++ quality.packages;
        shellHook = quality.shellHook;
      };
    };
}
