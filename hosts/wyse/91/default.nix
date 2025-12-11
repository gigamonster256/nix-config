{ config, ... }:
{
  unify.hosts.nixos.wyse-91 = {
    modules = with config.unify.modules; [
      wyse
    ];
    nixos = { };
  };
}
