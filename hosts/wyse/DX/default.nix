{ self, ... }:
{
  configurations.nixos.wyse-DX = {
    imports = with self.modules.nixos; [
      wyse
      technitium-dns
      backup
    ];
    services.technitium-dns-server.hostName = "ns1.nortonweb.org";
  };
}
