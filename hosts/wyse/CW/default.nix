{ self, ... }:
{
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
