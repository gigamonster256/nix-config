{ self, ... }:
{
  # IP/DNS identity (single source: feeds static IP assignment, forward +
  # reverse zones, and the ns2 alias).
  network-topology.hosts."wyse-CW" = {
    vlan = "servers";
    suffix = 51;
    aliases = [ "ns2" ];
  };

  configurations.nixos.wyse-CW = {
    imports = with self.modules.nixos; [
      wyse
      technitium-dns
      backup
      tinyca-updater
    ];
    services.technitium-dns-server.hostName = "ns2.nortonweb.org";
  };
}
