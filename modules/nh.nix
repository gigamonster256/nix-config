{ lib, config, ... }:
{
  unify.home = {
    programs.nh.flake = lib.mkDefault config.meta.flake;
  };
}
