{ self, ... }:
{
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
