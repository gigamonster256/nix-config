{
  description = "My nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lite-config.url = "github:yelite/lite-config";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    nh_plus = {
      url = "github:ToyVo/nh_plus";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-parts.follows = "flake-parts";
    };
    neovim-config = {
      url = "github:gigamonster256/neovim-config";
      flake = false;
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }: let
    overlays = import ./overlays {inherit inputs;};
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.git-hooks-nix.flakeModule
        inputs.lite-config.flakeModule
      ];
      systems = import inputs.systems;
      perSystem = {
        config,
        pkgs,
        ...
      }: {
        formatter = pkgs.alejandra;

        pre-commit.settings.hooks.alejandra.enable = true;
        devShells.default = config.pre-commit.devShell;
      };
      flake = {
        inherit overlays;
        nixosModules = import ./modules/nixos;
        darwinModules = import ./modules/darwin;
        homeManagerModules = import ./modules/home-manager;
      };
      lite-config = {
        nixpkgs = {
          config.allowUnfree = true;
          overlays = builtins.attrValues overlays;
          exportOverlayPackages = false;
          setPerSystemPkgs = false;
        };

        hostModuleDir = ./hosts;
        hosts = {
          chnorton-mbp = {
            system = "aarch64-darwin";
          };
          littleboy = {
            system = "x86_64-linux";
          };
        };

        # dummy home manager module to enable home manager
        # need to ask upstream to fix this
        homeModules = [{}];
        homeConfigurations = {
          "caleb@chnorton-mbp" = import ./home/chnorton-mbp.nix;
          "caleb@littleboy" = import ./home/littleboy.nix;
          chnorton = import ./home/chnorton.nix;
        };
      };
    };
}
