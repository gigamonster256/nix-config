{
  unify.nixos =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkIf
        ;
      cfg = config.backup;
      inherit (config.networking) hostName;
    in
    {
      # TODO: use restic instead?
      options.backup.fatman.enable = mkEnableOption "NFS backup mount to fatman.penguin";

      config = mkIf cfg.fatman.enable {
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

  unify.modules.backup.nixos =
    { lib, ... }:
    {
      backup.fatman.enable = lib.mkDefault true;
    };
}
