{
  description = "My nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # modular flakes
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # nix on macOS
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # declarative dotfiles
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # nix user repository
    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";
    nur.inputs.flake-parts.follows = "flake-parts";
    nur.inputs.treefmt-nix.follows = "treefmt-nix";

    # custom neovim config using nvf
    neovim.url = "github:gigamonster256/neovim-config/nvf";
    neovim.inputs.nixpkgs.follows = "nixpkgs";
    neovim.inputs.flake-parts.follows = "flake-parts";
    neovim.inputs.git-hooks.follows = "git-hooks";

    # secure boot
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.flake-parts.follows = "flake-parts";
    lanzaboote.inputs.pre-commit-hooks-nix.follows = "git-hooks";

    # declarative disk partitioning
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # erase your darlings
    impermanence.url = "github:nix-community/impermanence/home-manager-v2";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.inputs.home-manager.follows = "home-manager";

    # automatic hardware configuration
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";

    # hardware quirks/optimizations
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # gpg and age based secret management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # customized spotify the nix way
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    # pre-commit hooks
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # one format command to rule them all
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # , lsusb > nix shell nixpkgs#usbutils -c lsusb
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # pretty colors
    stylix.url = "github:nix-community/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    stylix.inputs.flake-parts.follows = "flake-parts";
    stylix.inputs.nur.follows = "nur";
    stylix.inputs.git-hooks.follows = "git-hooks";
    stylix.inputs.home-manager.follows = "home-manager";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    let
      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./modules/nixos;
      darwinModules = import ./modules/darwin;
      homeManagerModules = import ./modules/home-manager;
      flakeModules = import ./modules/flake;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
      ] ++ (builtins.attrValues flakeModules);
      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          treefmt = import ./treefmt.nix { inherit pkgs; };

          devShells.default = import ./shell.nix {
            inherit pkgs;
            # additionalShells = [config.pre-commit.devShell];
          };
        };
      flake = {
        inherit
          overlays
          nixosModules
          darwinModules
          homeManagerModules
          flakeModules
          ;
        images.tinyca =
          (self.nixosConfigurations.tinyca.extendModules {
            modules = [
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
            ];
          }).config.system.build.sdImage;
        ci = import ./ci.nix {
          inherit self;
          inherit (nixpkgs) lib;
        };
      };
      lite-config = {
        nixpkgs = {
          config.allowUnfree = true;
          overlays =
            with inputs;
            [
              neovim.overlays.default
              nur.overlays.default
            ]
            ++ (builtins.attrValues overlays);
          setPerSystemPkgs = true;
        };

        hostModules = [ ./hosts/modules ];
        nixosModules =
          [
            ./hosts/modules/nixos
          ]
          ++ (with inputs; [
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            lanzaboote.nixosModules.lanzaboote
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            nixos-facter-modules.nixosModules.facter
            spicetify-nix.nixosModules.default
            nix-index-database.nixosModules.nix-index
            stylix.nixosModules.stylix
          ])
          ++ (builtins.attrValues nixosModules);
        darwinModules =
          [
            ./hosts/modules/darwin
          ]
          ++ (with inputs; [
            stylix.darwinModules.stylix
          ])
          ++ (builtins.attrValues darwinModules);
        hosts = {
          chnorton-mbp = {
            system = "aarch64-darwin";
            modules = [ ./hosts/chnorton-mbp ];
          };
          chnorton-fw = {
            system = "x86_64-linux";
            modules = [
              ./hosts/chnorton-fw
              inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
              {
                home-manager = {
                  useGlobalPkgs = true;
                  users.caleb = ./home/chnorton-fw.nix;
                };
              }
            ];
          };
          littleboy = {
            system = "x86_64-linux";
            modules = [
              ./hosts/littleboy
              {
                home-manager = {
                  useGlobalPkgs = true;
                  users.caleb = ./home/littleboy.nix;
                };
              }
            ];
          };
          tinyca = {
            system = "aarch64-linux";
            modules = [
              # inputs.nixos-hardware.nixosModules.raspberry-pi-3
              ./hosts/pi-certs
            ];
          };
        };

        homeModules =
          [
            ./home/modules
          ]
          ++ (with inputs; [
            spicetify-nix.homeManagerModules.default
            nix-index-database.hmModules.nix-index
            impermanence.homeManagerModules.impermanence
          ])
          ++ (builtins.attrValues homeManagerModules);
        standaloneHomeModules = [
          inputs.stylix.homeModules.stylix # issues with being included in home-manager and nixos configuration... kinda clunky
        ];
        homeConfigurations = {
          "caleb@chnorton-mbp" = {
            modules = [ ./home/chnorton-mbp.nix ];
          };
          # "caleb@littleboy" = {modules = [./home/littleboy.nix];};
          chnorton = {
            modules = [ ./home/chnorton.nix ];
          };
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
