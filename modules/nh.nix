{ lib, config, ... }:
{
  unify.home = {
    programs.nh = {
      enable = lib.mkDefault true;
      flake = lib.mkDefault config.meta.flake;
    };
  };
}
