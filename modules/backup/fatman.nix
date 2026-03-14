{
  flake.modules.nixos.default =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.backup;
      inherit (config.networking) hostName;
    in
    {
      # TODO: use restic instead?
      options.backup.fatman.enable = lib.mkEnableOption "NFS backup mount to fatman.penguin";

      config = lib.mkIf cfg.fatman.enable {
        fileSystems."/mnt/backup" = {
          device = "fatman.penguin:/mnt/user/backups/${hostName}";
          fsType = "nfs";
          options = [
            "x-systemd.automount"
            "noauto"
            "x-systemd.idle-timeout=600"
          ];
        };
      };
    };

  flake.modules.nixos.backup =
    { lib, ... }:
    {
      backup.fatman.enable = lib.mkDefault true;
    };
}
