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
      "https://nix-community.cachix.org"
      "https://gigamonster256.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "gigamonster256.cachix.org-1:ySCUrOkKSOPm+UTipqGtGH63zybcjxr/Wx0UabASvRc="
    ];
    trusted-users = ["root"] ++ lib.attrNames config.users.users;
  };
}
