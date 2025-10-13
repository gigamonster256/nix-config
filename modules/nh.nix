{ lib, config, ... }:
{
  flake.modules.homeManager.base = {
    programs.nh.flake = lib.mkDefault config.meta.flake;
  };
}
