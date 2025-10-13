{ lib, config, ... }:
{
  flake.modules.homeManager.base = {
    programs.nh.flake = lib.mkDefault "github:gigamonster256/nix-config";
  };
}
