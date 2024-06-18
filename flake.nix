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
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    nh-darwin = {
      url = "github:ToyVo/nh-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // nix-darwin.lib // home-manager.lib;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    pkgsFor = lib.genAttrs systems (
      system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
    );

    forAllSystems = f: lib.genAttrs systems (system: f pkgsFor.${system});
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (pkgs: import ./pkgs {inherit pkgs;});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    devShells = forAllSystems (pkgs: import ./shell.nix {inherit pkgs;});

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
      littleboy = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/littleboy];
      };
    };

    # Available through 'darwin-rebuild --flake .#your-hostname'
    darwinConfigurations = {
      "chnorton-mbp" = lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/macbook];
      };
    };

    homeConfigurations = let
      mkConf = lib.homeManagerConfiguration;
    in {
      "caleb@littleboy" = mkConf {
        pkgs = pkgsFor."x86_64-linux";
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [./home/littleboy.nix];
      };

      "caleb@chnorton-mbp" = mkConf {
        pkgs = pkgsFor."aarch64-darwin";
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [./home/macbook.nix];
      };

      "chnorton@default" = mkConf {
        pkgs = pkgsFor."x86_64-linux";
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [./home/chnorton.nix];
      };
    };
  };
}
