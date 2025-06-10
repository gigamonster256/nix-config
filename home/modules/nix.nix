{
  inputs,
  lib,
  pkgs,
  config,
  systemConfig,
  ...
}:
let
  inherit (lib)
    mkDefault
    mapAttrs
    mapAttrsToList
    mkIf
    ;
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in
{
  nix = {
    package = mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
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
      warn-dirty = false;
      flake-registry = "";
    };
    registry = mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # actually install the specified nix in standalone mode
  home.packages = mkIf (systemConfig == null) [ config.nix.package ];
}
