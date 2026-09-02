{
  flake.diskoConfigurations.oppie = {
    disko.devices.disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-Fanxiang_S500Pro_512GB_26010869604002047";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
