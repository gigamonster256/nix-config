{
  # https://github.com/LedgerHQ/udev-rules/tree/master
  packages.ledger-udev-rules =
    {
      writeTextDir,
    }:
    writeTextDir "etc/udev/rules.d/99-ledger.rules" ''
      # HW.1, Nano
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"

      # Blue, NanoS, Aramis, HW.2, Nano X, NanoSP, Stax, Ledger Test,
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"

      # Same, but with hidraw-based library (instead of libusb)
      KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0666"
    '';

  unify.modules.crypto.nixos =
    { pkgs, ... }:
    {
      services.udev.packages = [ pkgs.ledger-udev-rules ];
      environment.systemPackages = [ pkgs.ledger-live-desktop ];
    };
}
