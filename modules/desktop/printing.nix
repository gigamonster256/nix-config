{
  flake.modules.nixos.desktop =
    { lib, pkgs, ... }:
    {
      services.printing = {
        enable = lib.mkDefault true;
        drivers = [
          pkgs.cups-brother-hll2315dw
        ];
      };
      # CUPS D-Bus calls to fprintd cause 30 second hangs in the web UI
      security.pam.services.cups.fprintAuth = lib.mkDefault false;
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

  nixpkgs.allowedUnfreePackages = [
    "brgenml1lpr"
  ];

  flake.modules.nixos.laptop =
    { pkgs, ... }:
    {
      services.printing = {
        drivers = [
          # hplib is pretty heavy, can it be trimmed down?
          pkgs.hplip
          pkgs.brgenml1cupswrapper
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
        {
          name = "Brother_MFC-7360N";
          deviceUri = "usb://Brother/MFC-7360N?serial=U62700J1N112001";
          location = "IEEE Lounge";
          model = "brother-BrGenML1-cups-en.ppd";
        }
      ];
    };

}
