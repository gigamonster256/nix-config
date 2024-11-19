{
  description = "My nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    systems.url = "github:nix-systems/default";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    nh_darwin = {
      url = "github:ToyVo/nh_darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    neovim-config = {
      url = "github:gigamonster256/neovim-config";
      flake = false;
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    home-manager,
    nix-darwin,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // nix-darwin.lib // home-manager.lib // flake-utils.lib;

    pkgsFor = lib.genAttrs lib.allSystems (
      system:
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues outputs.overlays;
          config.allowUnfree = true;
        }
    );

    mkHomeManager = {
      system,
      user,
      hostname ? null,
    }: let
      homeModule =
        if (hostname == null)
        then ./home/${user}.nix
        else ./home/${hostname}.nix;
      configurationName =
        if (hostname == null)
        then user
        else "${user}@${hostname}";
    in {
      homeConfigurations."${configurationName}" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.${system};
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [homeModule];
      };
    };

    mkSystem = {
      os,
      system,
      hostname,
      homeUser ? "",
    }:
      {
        "${os}Configurations".${hostname} = lib."${os}System" {
          pkgs = pkgsFor.${system};
          specialArgs = {inherit inputs outputs;};
          modules =
            [./hosts/${hostname}]
            ++ (lib.optionals (homeUser != "") [
              home-manager."${os}Modules".default
              {
                home-manager = {
                  extraSpecialArgs = {inherit inputs outputs;};
                  useGlobalPkgs = true;
                  # useUserPackages = true;
                  users.${homeUser} = import ./home/${hostname}.nix;
                  # sharedModules = [./home/${hostname}.nix];
                };
              }
            ]);
        };
      }
      //
      # automatically generate a home-manager configuration for this system
      (
        if (homeUser != "")
        then
          mkHomeManager {
            inherit system hostname;
            user = homeUser;
          }
        else {}
      );
  in
    lib.fold lib.recursiveUpdate
    (flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = pkgsFor.${system};
      in rec {
        packages = import ./pkgs {inherit pkgs;};
        formatter = pkgs.alejandra;
        checks = {
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              alejandra.enable = true;
            };
          };
        };
        devShells = let inherit (checks.pre-commit-check) shellHook; in import ./shell.nix {inherit pkgs shellHook;};
      }
    ))
    [
      {
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

      (mkSystem {
        os = "nixos";
        system = "x86_64-linux";
        hostname = "littleboy";
        homeUser = "caleb";
      })
      (mkSystem {
        os = "darwin";
        system = "aarch64-darwin";
        hostname = "chnorton-mbp";
        homeUser = "caleb";
      })
      (mkHomeManager {
        system = "x86_64-linux";
        user = "chnorton";
      })
    ];
}
