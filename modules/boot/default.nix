{
  unify.nixos =
    { lib, ... }:
    {
      boot = {
        initrd.systemd.enable = lib.mkDefault true;
        loader = {
          systemd-boot.enable = lib.mkDefault true;
          efi.canTouchEfiVariables = true;
          timeout = lib.mkOverride 750 0;
        };
        # kernel.sysctl = {
        #   "transparent_hugepage" = "always";
        #   "vm.nr_hugepages_defrag" = 0;
        #   "ipcs_shm" = 1;
        #   "default_hugepagez" = "1G";
        #   "hugepagesz" = "1G";
        #   "vm.swappiness" = 1;
        #   "vm.compact_memory" = 0;
        # };
        # supportedFilesystems = [ "ntfs" ]; # Adds NTFS driver
      };
    };
}
