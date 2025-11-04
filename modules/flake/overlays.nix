{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.neovim.overlays.default
    inputs.nur.overlays.default
  ]
  ++ (builtins.attrValues inputs.self.overlays);

  unify.nixos = {
    nixpkgs.overlays = [
      inputs.neovim.overlays.default
      inputs.nur.overlays.default
    ]
    ++ (builtins.attrValues inputs.self.overlays);
  };

  flake.overlays = {
    # This one brings our custom packages from the 'packages' output of this flake
    # additions = final: _prev: inputs.self.packages.${final.stdenv.hostPlatform.system};

    # This one contains whatever you want to overlay
    # You can change versions, add patches, set compilation flags, anything really.
    # https://nixos.wiki/wiki/Overlays
    modifications = _final: _prev: {
      # custom trilium-next-desktop package
      # trilium-desktop = (customPkgs final).trilium-next-desktop;
    };

    # # induced by https://github.com/NixOS/nixpkgs/pull/385341 and backports to 24.11
    # # using the --unpack hash
    # electron_shananagains = final: prev: {
    #   electron_35 = prev.electron_35.overrideAttrs (oldAttrs: {
    #     passthru.headers =
    #       let
    #         headersFetcher =
    #           vers: hash:
    #           final.fetchurl {
    #             url = "https://artifacts.electronjs.org/headers/dist/v${vers}/node-v${vers}-headers.tar.gz";
    #             sha256 = hash;
    #           };
    #       in
    #       # nix-prefetch-url url (not using --unpack)
    #       headersFetcher oldAttrs.version "19b6amp8cqhgmif5rmgi7vayyr8m7mh8b179s3f4azxyzfis192z";
    #   });
    # };

    # # When applied, the unstable nixpkgs set (declared in the flake inputs) will
    # # be accessible through 'pkgs.unstable'
    # unstable-packages = final: _prev: {
    #   unstable = import inputs.nixpkgs-unstable {
    #     inherit (final) system;
    #     config.allowUnfree = true;
    #   };
    # };

    ghostty-bin-tip = final: prev: {
      ghostty =
        if final.stdenv.hostPlatform.isDarwin then
          prev.ghostty-bin
        else
          (inputs.ghostty.overlays.default final prev).ghostty;
    };

    # flake-schemas = final: prev: {
    #   # 2.27 is used in the flake-schema as the base
    #   # but has been removed from nixpkgs so use 2.28 derivation
    #   nix = prev.nixVersions.nix_2_28.overrideAttrs (_oldAttrs: {
    #     version = "2.27-flake-schemas";
    #     src = final.fetchFromGitHub {
    #       owner = "DeterminateSystems";
    #       repo = "nix-src";
    #       rev = "flake-schemas";
    #       hash = "sha256-Yy1Cd3Xm4UJTctYsVQfD5jY5z7pVncvLu8cq0cjjYT4=";
    #     };
    #   });
    # };
  };
}
