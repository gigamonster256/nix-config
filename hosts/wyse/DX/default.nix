{ config, ... }:
{
  unify.hosts.nixos.wyse-DX = {
    modules = with config.unify.modules; [
      wyse
      technitium-dns
      backup
    ];
    nixos = {
      services.technitium-dns-server.hostName = "ns1.nortonweb.org";
    };
  };
}
