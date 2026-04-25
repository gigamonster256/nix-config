{ lib, config, ... }:
{
  nixpkgs.overlays = [
    (_final: prev: {
      nh-unwrapped = prev.nh-unwrapped.overrideAttrs (old: {
        patches = old.patches or [ ];
      });
    })
  ];

  flake.modules.homeManager.default = {
    programs.nh = {
      enable = lib.mkDefault true;
      flake = lib.mkDefault config.meta.flake;
    };
  };
}
