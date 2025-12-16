{ config, ... }:
{
  unify.hosts.nixos.wyse-CW = {
    modules = with config.unify.modules; [
      wyse
      technitium-dns
      backup
    ];
    nixos = {
      services.technitium-dns-server.hostName = "ns2.nortonweb.org";
    };
  };
}
