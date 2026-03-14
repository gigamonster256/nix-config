{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib) types;
in
{
  options.nixpkgs = {
    allowedUnfreePackages = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    permittedInsecurePackages = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    overlays = lib.mkOption {
      type = types.listOf (
        types.uniq (types.functionTo (types.functionTo (types.lazyAttrsOf types.unspecified)))
      );
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
      flake.modules.nixos.default = {
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
