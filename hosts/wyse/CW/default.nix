{ config, ... }:
{
  unify.hosts.nixos.wyse-CW = {
    modules = with config.unify.modules; [
      wyse
    ];
    nixos = { };
  };
}
