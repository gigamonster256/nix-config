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
    gigamonster256-nur = {
      url = "github:gigamonster256/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lite-config.url = "github:gigamonster256/lite-config";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    neovim-config = {
      url = "github:gigamonster256/neovim-config/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}: let
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
          overlays =
            (builtins.attrValues overlays)
            ++ [
              inputs.neovim-config.overlays.default
            ];
          exportOverlayPackages = false;
          setPerSystemPkgs = false;
        };

        hostModuleDir = ./hosts;
        hosts = {
          chnorton-mbp.system = "aarch64-darwin";
          littleboy.system = "x86_64-linux";
        };

        homeConfigurations = {
          "caleb@chnorton-mbp" = import ./home/chnorton-mbp.nix;
          "caleb@littleboy" = import ./home/littleboy.nix;
          chnorton = import ./home/chnorton.nix;
        };
      };
    };
}
