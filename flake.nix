{
  description = "My nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    gigamonster256-nur.url = "github:gigamonster256/nur-packages";
    gigamonster256-nur.inputs.nixpkgs.follows = "nixpkgs";

    neovim.url = "github:gigamonster256/neovim-config/nvf";
    neovim.inputs.nixpkgs.follows = "nixpkgs-unstable";
    neovim.inputs.flake-parts.follows = "flake-parts";
    neovim.inputs.git-hooks.follows = "git-hooks";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-hardware,
    flake-parts,
    git-hooks,
    neovim,
    lanzaboote,
    sops-nix,
    spicetify-nix,
    nix-index-database,
    ...
  }: let
    overlays = import ./overlays {inherit inputs;};
    nixosModules = import ./modules/nixos;
    darwinModules = import ./modules/darwin;
    homeManagerModules = import ./modules/home-manager;
    flakeModules = import ./modules/flake;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [git-hooks.flakeModule] ++ (builtins.attrValues flakeModules);
      perSystem = {
        config,
        pkgs,
        ...
      }: {
        formatter = pkgs.alejandra;

        pre-commit.settings.hooks.alejandra.enable = true;
        devShells.default = import ./shell.nix {
          inherit pkgs;
          additionalShells = [config.pre-commit.devShell];
        };
      };
      flake = {
        inherit overlays nixosModules darwinModules homeManagerModules flakeModules;
        images.tinyca =
          (self.nixosConfigurations.tinyca.extendModules {
            modules = ["${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"];
          })
          .config
          .system
          .build
          .sdImage;
        ci = import ./ci.nix {
          inherit self;
          inherit (nixpkgs) lib;
        };
      };
      lite-config = {
        nixpkgs = {
          config.allowUnfree = true;
          overlays = [neovim.overlays.default] ++ (builtins.attrValues overlays);
          setPerSystemPkgs = true;
        };

        hostModules = [./hosts/modules];
        nixosModules =
          [
            ./hosts/modules/nixos
            sops-nix.nixosModules.sops
            lanzaboote.nixosModules.lanzaboote
          ]
          ++ (builtins.attrValues nixosModules);
        darwinModules = [./hosts/modules/darwin] ++ (builtins.attrValues darwinModules);
        hosts = {
          chnorton-mbp = {
            system = "aarch64-darwin";
            modules = [./hosts/chnorton-mbp];
          };
          littleboy = {
            system = "x86_64-linux";
            modules = [./hosts/littleboy];
          };
          tinyca = {
            system = "aarch64-linux";
            modules = [
              nixos-hardware.nixosModules.raspberry-pi-3
              ./hosts/pi-certs
            ];
          };
        };

        homeModules =
          [
            ./home/modules
            spicetify-nix.homeManagerModules.default
            nix-index-database.hmModules.nix-index
          ]
          ++ (builtins.attrValues homeManagerModules);
        homeConfigurations = {
          "caleb@chnorton-mbp" = {modules = [./home/chnorton-mbp.nix];};
          "caleb@littleboy" = {modules = [./home/littleboy.nix];};
          chnorton = {modules = [./home/chnorton.nix];};
        };
      };
    };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://gigamonster256.cachix.org"
      "https://lanzaboote.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "gigamonster256.cachix.org-1:ySCUrOkKSOPm+UTipqGtGH63zybcjxr/Wx0UabASvRc="
      "lanzaboote.cachix.org-1:Nt9//zGmqkg1k5iu+B3bkj3OmHKjSw9pvf3faffLLNk="
    ];
  };
}
