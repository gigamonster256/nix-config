{
  description = "My nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    nh-darwin = {
      url = "github:ToyVo/nh-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      # follow the nixpkgs channel once 24.05 stabilizes https://github.com/nix-community/neovim-nightly-overlay/issues/533
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    hyprland,
    sops-nix,
    nix-darwin,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};
    # Reusable nixos modules you might want to export
    # These are usually stuff you would upstream into nixpkgs
    nixosModules = import ./modules/nixos;
    # Reusable nix-darwin modules you might want to export
    # These are usually stuff you would upstream into nix-darwin
    darwinModules = import ./modules/darwin;
    # Reusable home-manager modules you might want to export
    # These are usually stuff you would upstream into home-manager
    homeManagerModules = import ./modules/home-manager;

    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      littleboy = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/littleboy];
      };
    };

    # Available through 'darwin-rebuild --flake .#your-hostname'
    darwinConfigurations = {
      "chnorton-mbp" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [./hosts/macbook];
        specialArgs = {inherit inputs outputs;};
      };
    };

    homeConfigurations = let
      mkConf = home-manager.lib.homeManagerConfiguration;
    in {
      "caleb@littleboy" = mkConf {
        pkgs = pkgsFor "x86_64-linux";
        modules = [./home/littleboy.nix];
        extraSpecialArgs = {inherit inputs outputs;};
      };

      "caleb@chnorton-mbp" = mkConf {
        pkgs = pkgsFor "aarch64-darwin";
        modules = [./home/macbook.nix];
        extraSpecialArgs = {inherit inputs outputs;};
      };

      "chnorton@default" = mkConf {
        pkgs = pkgsFor "x86_64-linux";
        modules = [./home/chnorton.nix];
        extraSpecialArgs = {inherit inputs outputs;};
      };
    };
  };
}
