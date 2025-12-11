{ config, ... }:
{
  unify.hosts.nixos.wyse-F8 = {
    modules = with config.unify.modules; [
      wyse
    ];
    nixos = { };
  };
}
