{
  description = "My nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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

    # custom neovim config using nvf
    neovim.url = "github:gigamonster256/neovim-config/nvf";
    neovim.inputs.nixpkgs.follows = "nixpkgs";
    neovim.inputs.flake-parts.follows = "flake-parts";
    neovim.inputs.git-hooks.follows = "git-hooks";

    # secure boot
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.3";
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

    # flake schemas - use roles branch to stay in sync with detsys/nix-src/flake-schemas
    # flake-schemas.url = "github:DeterminateSystems/flake-schemas/roles";

    # gh actions for nix
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";

    # import tree
    import-tree.url = "github:vic/import-tree";

    # master ghostty
    ghostty.url = "github:ghostty-org/ghostty";
    ghostty.inputs.nixpkgs.follows = "nixpkgs";

    # unify system config framework
    unify.url = "git+https://codeberg.org/quasigod/unify";
    unify.inputs.nixpkgs.follows = "nixpkgs";
    unify.inputs.home-manager.follows = "home-manager";
    unify.inputs.flake-parts.follows = "flake-parts";
  };

  outputs =
    { flake-parts, import-tree, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      imports = [
        inputs.unify.flakeModule
        # inputs.flake-parts.flakeModules.flakeModules
        # inputs.flake-parts.flakeModules.partitions
        inputs.flake-parts.flakeModules.modules
        inputs.home-manager.flakeModules.home-manager
        inputs.treefmt-nix.flakeModule
        inputs.disko.flakeModules.default
        (import-tree [
          ./hosts
          ./modules
          ./pkgs
        ])
      ];

      meta.owner = {
        name = "Caleb Norton";
        email = "n0603919@outlook.com";
      };
      meta.flake = "github:gigamonster256/nix-config";

      perSystem =
        { pkgs, ... }:
        {
          treefmt = import ./treefmt.nix { inherit pkgs; };
          devShells.default = import ./shell.nix { inherit pkgs; };
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
