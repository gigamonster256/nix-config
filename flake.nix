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
          overlays = [
            outputs.overlays.additions
            outputs.overlays.modifications
            outputs.overlays.unstable-packages
          ];
          config.allowUnfree = true;
        }
    );

    mkHomeManager = {
      system,
      user,
      hostname,
    }: {
      homeConfigurations."${user}@${hostname}" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.${system};
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [./home/${hostname}.nix];
      };
    };

    mkSystem = {
      os,
      system,
      hostname,
      user ? "",
    }:
      {
        "${os}Configurations".${hostname} = lib."${os}System" {
          pkgs = pkgsFor.${system};
          specialArgs = {inherit inputs outputs;};
          modules =
            [./hosts/${hostname}]
            ++ (lib.optionals (user != "") [
              home-manager."${os}Modules".default
              {
                home-manager = {
                  extraSpecialArgs = {inherit inputs outputs;};
                  useGlobalPkgs = true;
                  # useUserPackages = true;
                  users.${user} = import ./home/${hostname}.nix;
                  # sharedModules = [./home/${hostname}.nix];
                };
              }
            ]);
        };
      }
      //
      # automatically generate a home-manager configuration for this system
      (
        if (user != "")
        then mkHomeManager {inherit system user hostname;}
        else {}
      );

    forAllSystems = f: lib.genAttrs systems (system: f pkgsFor.${system});
  in
    lib.fold lib.recursiveUpdate
    {
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
    }
    # systems (recursively merged)
    [
      (mkSystem {
        os = "nixos";
        system = "x86_64-linux";
        hostname = "littleboy";
        user = "caleb";
      })
      (mkSystem {
        os = "darwin";
        system = "aarch64-darwin";
        hostname = "chnorton-mbp";
        user = "caleb";
      })
      (mkHomeManager {
        system = "x86_64-linux";
        user = "chnorton";
        hostname = "default";
      })
    ];
}
