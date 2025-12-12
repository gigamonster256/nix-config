{ config, ... }:
{
  unify.hosts.nixos.wyse-DX = {
    modules = with config.unify.modules; [
      wyse
      technitium-dns
    ];
    nixos = {
      services.technitium-dns-server.hostName = "ns1.nortonweb.org";
    };
  };
}
