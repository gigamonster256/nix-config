{
  config,
  lib,
  ...
}: {
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations"
    ];
    substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://gigamonster256.cachix.org"
      # crate2nix
      "https://eigenvalue.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "gigamonster256.cachix.org-1:ySCUrOkKSOPm+UTipqGtGH63zybcjxr/Wx0UabASvRc="
      "eigenvalue.cachix.org-1:ykerQDDa55PGxU25CETy9wF6uVDpadGGXYrFNJA3TUs="
    ];
    trusted-users = ["root"] ++ lib.attrNames config.users.users;
  };
}
