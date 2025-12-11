{ config, ... }:
{
  unify.hosts.nixos.wyse-F4 = {
    modules = with config.unify.modules; [
      wyse
    ];
    nixos = { };
  };
}
