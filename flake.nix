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
    # until treesitter issues are resolved
    # neovim.inputs.nixpkgs.follows = "nixpkgs";
    neovim.inputs.flake-parts.follows = "flake-parts";
    neovim.inputs.git-hooks.follows = "git-hooks";

    # secure boot
    lanzaboote.url = "github:nix-community/lanzaboote/v1.0.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.pre-commit.follows = "";

    # declarative disk partitioning
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # erase your darlings
    impermanence.url = "github:nix-community/impermanence";
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
    ghostty.inputs.zon2nix.follows = ""; # dev only

    persistence.url = "github:gigamonster256/persistence";
    # persistence.inputs.nixpkgs.follows = "nixpkgs";
    persistence.inputs.flake-parts.follows = "flake-parts";
    persistence.inputs.impermanence.follows = "impermanence";
    persistence.inputs.import-tree.follows = "import-tree";
    # bus notifications service
    bussy.url = "github:gigamonster256/bussy";
    bussy.inputs.nixpkgs.follows = "nixpkgs";
    bussy.inputs.devenv.follows = ""; # don't need devenv for deployment

    # latest opencode dev desktop and cli
    opencode.url = "github:anomalyco/opencode";
    # need newer nixpkgs for newer bun
    # opencode.inputs.nixpkgs.follows = "nixpkgs";

    opencode-tamu-finish-fix.url = "github:gigamonster256/opencode-tamu-finish-fix";
    opencode-tamu-finish-fix.flake = false;

    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";
    noctalia.inputs.noctalia-qs.inputs.treefmt-nix.follows = "treefmt-nix";

    determinate.url = "github:DeterminateSystems/determinate";
    determinate.inputs.nixpkgs.follows = "nixpkgs";
    determinate.inputs.nix.inputs.flake-parts.follows = "flake-parts";
    determinate.inputs.nix.inputs.git-hooks-nix.follows = "git-hooks";
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
        # inputs.flake-parts.flakeModules.flakeModules
        # inputs.flake-parts.flakeModules.partitions
        (import-tree [
          ./hosts
          ./modules
          ./pkgs
          ./scripts
        ])
      ];

      meta.owner = {
        name = "Caleb Norton";
        email = "n0603919@outlook.com";
        sshKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOevicH4lyiFYuIcUPKSvu3+zjY67wzLkkCCN3Er7Hff caleb@chnorton-fw"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+r3cAB0MVWfjOEfKfaIiIKQH+oGVroILI6ZZBsazyZvv+5tv+Ruw7nsbePG4JZlz356Zh4/csTrnrutYHOw6t7fWODKOvPBr3qDjNNbenuT7SUqOwZvBk5Du7zQ9VYq3qnHay+lw9BDcf0TruISlFihiL7yeC7jSm3+AAJW+vr6JV6J0wVnZ25/x3Sje1UL2GVyTr8HrGB+HRTHDINfkQG5jZCNyyFy9FEu6BuPHsOfDL0pgSBMxBPI4OkVPUUKHugmFqxsEaj4y87IUbRhGAyZBXIJ9e6zoRIdDZ5agF7ztHIletjYeJ9sDQyeXuGx6LMJI03A4GJyGJFSdxE+Gu0z16kr03UT+1czL+k98PZyo9JVIB0HsFBdhVCzJKDzi128WBrvCJQ6XRpKSYYfWzXYP5bVOFwM2vEpT0IgvZX6AdbdubFluCaWf6Aw2Ui2n786z2EqcPcj8qrF5GjGWcYg28n+LhJZGMu2RyKy17NisopLt+dIeQkAHqKFSfsHe4YJNkJJlkZFr1a/cM57JJu8EnUeR/y2IH8lzME1GS5yIFNAmDgskE0LbBvjtDwzaUmr7uRX8RGkvFb4nV1cG79wb+ROnyEtSfZ8fLreimPGL5JhJKOBAQLAxAbf1tv4I0K8TNtYGcCxD0Ugl8XLI8ScvuqXT1u3Kzk6kRYucj+Q== openpgp:0xAD72366B"
        ];
      };
      meta.flake = "github:gigamonster256/nix-config";
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
