{ self, lib, ... }:
{
  flake.modules.nixos.base =
    { config, ... }:
    let
      inherit (lib) mkIf mkMerge;
      cfg = config.impermanence;
    in
    mkIf cfg.enable (mkMerge [
      (mkIf config.hardware.bluetooth.enable {
        impermanence.directories = [ "/var/lib/bluetooth" ];
      })
      (mkIf config.services.fprintd.enable {
        impermanence.directories = [ "/var/lib/fprint" ];
      })
      (mkIf config.boot.lanzaboote.enable {
        impermanence.directories = [ config.boot.lanzaboote.pkiBundle ];
      })
    ]);
}
