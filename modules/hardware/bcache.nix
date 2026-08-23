{
  flake.modules.nixos.default =
    { lib, config, ... }:
    # bcache needs both a backing device and a caching device, so it is pointless
    # (and pulls in bcache-tools) on machines with only a single physical drive.
    # Disable it automatically when the facter report shows just one disk.
    lib.mkIf (config ? facter && (lib.length (config.facter.report.hardware.disk or [ ]) == 1)) {
      boot.bcache.enable = lib.mkDefault false;
    };
}
