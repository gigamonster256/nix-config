{ config, ... }:
{
  unify.hosts.nixos.wyse-91 = {
    modules = with config.unify.modules; [
      wyse
      uptime-kuma
      backup
      n7m-t8r
      agari
    ];
    nixos = { };
  };
}
