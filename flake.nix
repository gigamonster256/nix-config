{
  description = "My nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    gigamonster256-nur.url = "github:gigamonster256/nur-packages";
    gigamonster256-nur.inputs.nixpkgs.follows = "nixpkgs";

    neovim.url = "github:gigamonster256/neovim-config/nvf";
    neovim.inputs.nixpkgs.follows = "nixpkgs-unstable";

    lite-config.url = "github:gigamonster256/lite-config";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: Remove once 4.0 is released
    nh.url = "github:viperML/nh";
    nh.inputs.nixpkgs.follows = "nixpkgs-unstable";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    flake-parts,
    lite-config,
    git-hooks,
    neovim,
    ...
  }: let
    overlays = import ./overlays {inherit inputs;};
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        git-hooks.flakeModule
        lite-config.flakeModule
      ];
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
        inherit overlays;
        nixosModules = import ./modules/nixos;
        darwinModules = import ./modules/darwin;
        homeManagerModules = import ./modules/home-manager;
      };
      lite-config = {
        nixpkgs = {
          config.allowUnfree = true;
          overlays = (builtins.attrValues overlays) ++ [neovim.overlays.default];
          setPerSystemPkgs = true;
        };

        hostModules = [./hosts/modules];
        hosts = {
          chnorton-mbp = {
            system = "aarch64-darwin";
            modules = [./hosts/chnorton-mbp ./hosts/darwin-modules];
          };
          littleboy = {
            system = "x86_64-linux";
            modules = [./hosts/littleboy];
          };
        };

        homeModules = [./home/modules];
        homeConfigurations = {
          "caleb@chnorton-mbp" = {modules = [./home/chnorton-mbp.nix];};
          "caleb@littleboy" = {modules = [./home/littleboy.nix];};
          chnorton = {modules = [./home/chnorton.nix];};
        };
      };
    };
}
