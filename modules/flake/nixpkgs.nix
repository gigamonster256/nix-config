{
  inputs,
  lib,
  config,
  ...
}:
{
  options.nixpkgs = {
    allowedUnfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    permittedInsecurePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    overlays = lib.mkOption {
      type = with lib.types; listOf (uniq (functionTo (functionTo (lazyAttrsOf unspecified))));
      default = [ ];
    };
  };

  config =
    let
      cfg = config.nixpkgs;
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.allowedUnfreePackages;
      nixpkgs = {
        inherit (cfg) overlays;
        config = {
          inherit allowUnfreePredicate;
          inherit (cfg) permittedInsecurePackages;
          # nice for readability but causes mass-rebuilds
          # fetchedSourceNameDefault = "versioned"; # or "full"
        };
      };
    in
    {
      # configure the pkgs used in nixos, home-manager
      unify.nixos = {
        inherit nixpkgs;
      };

      flake.modules.darwin.base = {
        inherit nixpkgs;
      };

      # only standalone home-manager needs nixpkgs since used under nixos
      # or nix-darwin uses useGlobalPkgs = true
      flake.modules.homeManager.standalone = {
        inherit nixpkgs;
      };

      # allow unfree packages in overlays/flake packages
      perSystem =
        { system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs (nixpkgs // { inherit system; });
        };
    };
}
