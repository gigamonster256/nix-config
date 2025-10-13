let
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
in
{ inputs, lib, ... }:
let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
  nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
in
{
  flake.modules.nixos.base = {
    nix = {
      settings = {
        inherit
          experimental-features
          extra-substituters
          extra-trusted-public-keys
          warn-dirty
          flake-registry
          ;
        trusted-users = [
          "root"
          "@wheel"
          "caleb"
        ];
      };
      inherit registry nixPath;
    };
  };
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      nix = {
        package = lib.mkDefault pkgs.nix;
        settings = {
          inherit
            experimental-features
            extra-substituters
            extra-trusted-public-keys
            warn-dirty
            flake-registry
            ;
        };
        inherit registry nixPath;
      };
    };

  flake.modules.homeManager.standalone =
    { config, ... }:
    {
      home.packages = [ config.nix.package ];
    };
}
