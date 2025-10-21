{
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.nixpkgs;
  allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.allowedUnfreePackages;
in
{
  options.nixpkgs = {
    allowedUnfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    overlays = lib.mkOption {
      type = with lib.types; listOf (uniq (functionTo (functionTo (lazyAttrsOf unspecified))));
      default = [ ];
    };
  };

  config = {
    # configure the pkgs used in nixos, home-manager

    unify.nixos = {
      nixpkgs = {
        inherit (cfg) overlays;
        config = { inherit allowUnfreePredicate; };
      };
    };

    flake.modules.darwin.base.nixpkgs = {
      inherit (cfg) overlays;
      config = { inherit allowUnfreePredicate; };
    };

    # only standalone home-manager needs nixpkgs since used under nixos
    # or nix-darwin uses useGlobalPkgs = true
    flake.modules.homeManager.standalone = {
      nixpkgs = {
        inherit (cfg) overlays;
        config = { inherit allowUnfreePredicate; };
      };
    };

    # allow unfree packages in overlays/flake packages
    perSystem =
      { system, ... }:
      {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          inherit (cfg) overlays;
          config = { inherit allowUnfreePredicate; };
        };
      };
  };
}
