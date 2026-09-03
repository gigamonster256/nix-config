{ self, ... }:
{
  # IP/DNS identity (single source: feeds static IP assignment plus forward
  # and reverse zones).
  network-topology.hosts."wyse-91" = {
    vlan = "servers";
    suffix = 52;
  };

  configurations.nixos.wyse-91 = {
    imports = with self.modules.nixos; [
      wyse
      uptime-kuma
      backup
      n7m-t8r
      agari
    ];
  };
}
