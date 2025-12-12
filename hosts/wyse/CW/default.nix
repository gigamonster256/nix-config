{ config, ... }:
{
  unify.hosts.nixos.wyse-CW = {
    modules = with config.unify.modules; [
      wyse
      technitium-dns
    ];
    nixos = {
      services.technitium-dns-server.hostName = "ns2.nortonweb.org";
    };
  };
}
