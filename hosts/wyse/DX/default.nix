{ config, ... }:
{
  unify.hosts.nixos.wyse-DX = {
    modules = with config.unify.modules; [
      wyse
    ];
    nixos = { };
  };
}
