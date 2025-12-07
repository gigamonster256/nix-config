{
  unify.modules.desktop.nixos =
    { lib, pkgs, ... }:
    {
      services.printing = {
        enable = lib.mkDefault true;
        drivers = [
            pkgs.cups-brother-hll2315dw
        ];
      };
      hardware.printers.ensurePrinters = [
        {
          name = "printer";
          deviceUri = "lpd://printer.penguin";
          location = "Living Room";
          model = "brother-HLL2315DW-cups-en.ppd";
          # lpoptions -p <name> -l
          ppdOptions = {
            PageSize = "Letter";
          };
        }
      ];
    };
}
