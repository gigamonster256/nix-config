{ pkgs }:
{
  builtin = pkgs.callPackage ./builtin.nix { };
  "aerospace.sh" = pkgs.callPackage ./aerospace.nix { };
}
