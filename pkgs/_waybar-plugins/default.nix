{ pkgs }:
{
  vpn-status = pkgs.callPackage ./vpn-status.nix { };
}
