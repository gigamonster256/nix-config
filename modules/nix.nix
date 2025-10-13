{
  flake.modules.nixos.base =
    {
      inputs,
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib) filterAttrs mapAttrs mapAttrsToList;
      flakeInputs = filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      nix = {
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
          trusted-users = [
            "root"
            "@wheel"
            "@staff"
            "caleb"
          ];
        };
        registry = mapAttrs (_: flake: { inherit flake; }) flakeInputs;
        nixPath = mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      };
    };
}
