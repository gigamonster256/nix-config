{
  unify.modules = {
    desktop.nixos =
      { lib, pkgs, ... }:
      {
        services.printing = {
          enable = lib.mkDefault true;
          drivers = [
            pkgs.cups-brother-hll2315dw
          ];
        };
        hardware.printers = {
          ensureDefaultPrinter = "home_printer";
          ensurePrinters = [
            {
              name = "home_printer";
              deviceUri = "lpd://printer.penguin/binary_p1";
              location = "Living Room";
              # lpinfo -m
              model = "brother-HLL2315DW-cups-en.ppd";
              # lpoptions -p <name> -l
              ppdOptions = {
                PageSize = "Letter";
              };
            }
          ];
        };
      };

    laptop.nixos =
      { pkgs, ... }:
      {
        services.printing = {
          drivers = [
            # hplib is pretty heavy, can it be trimmed down?
            pkgs.hplip
          ];
        };
        hardware.printers.ensurePrinters = [
          {
            name = "work_printer";
            deviceUri = "lpd://ECEN-WEB052-HPP2055dn.engr.tamu.edu";
            location = "WEB 052";
            model = "drv:///hp/hpcups.drv/hp-laserjet_p2055dn-pcl3.ppd";
            ppdOptions = {
              PageSize = "Letter";
              OptionDuplex = "True";
            };
          }
        ];
      };
  };
}
