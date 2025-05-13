{
  lib,
  utils,
  pkgs,
  config,
  ...
}:
{
  options = {
    impermanence = {
      enable = lib.mkEnableOption "impermanence";
      persistPath = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "/persist";
      };
      btrfsWipe = {
        enable = lib.mkEnableOption "btrfs wipe";
        device = lib.mkOption {
          default = config.fileSystems."/".device;
        };
        rootSubvolume = lib.mkOption {
          default = "root";
        };
      };
    };
  };
  config =
    let
      cfg = config.impermanence;
    in
    lib.mkIf cfg.enable {
      # TODO: make this flexible/more correct
      assertions = [
        {
          assertion = cfg.btrfsWipe.enable == false || config.fileSystems."/".fsType == "btrfs";
          message = "impermanence.btrfsWipe.enable requires btrfs filesystem";
        }
      ];
      fileSystems."${cfg.persistPath}".neededForBoot = true;
      environment.persistence."${cfg.persistPath}" = {
        hideMounts = true;
        directories = [
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/bluetooth"
          "/var/lib/systemd/coredump"
          config.boot.lanzaboote.pkiBundle
        ];
        files = [
          "/etc/machine-id"
        ] ++ (builtins.map (lib.removePrefix cfg.persistPath) config.sops.age.sshKeyPaths);
      };
      boot.initrd.systemd =
        let
          cfg = config.impermanence.btrfsWipe;
        in
        lib.mkIf cfg.enable {
          extraBin = {
            mkdir = "${pkgs.coreutils}/bin/mkdir";
          };
          services.btrfs-wipe = {
            description = "Prepare btrfs subvolumes for root";
            wantedBy = [ "initrd.target" ];
            after = [ "${utils.escapeSystemdPath cfg.device}.device" ];
            before = [ "sysroot.mount" ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig.Type = "oneshot";
            script = ''
              mkdir /btrfs_tmp
              mount ${cfg.device} /btrfs_tmp
              if [[ -e /btrfs_tmp/${cfg.rootSubvolume} ]]; then
                  mkdir -p /btrfs_tmp/old_roots
                  timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/${cfg.rootSubvolume})" "+%Y-%m-%-d_%H:%M:%S")
                  mv /btrfs_tmp/${cfg.rootSubvolume} "/btrfs_tmp/old_roots/$timestamp"
              fi

              delete_subvolume_recursively() {
                  IFS=$'\n'
                  for subvol in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                      delete_subvolume_recursively "/btrfs_tmp/$subvol"
                  done
                  btrfs subvolume delete "$1"
              }

              # Delete old roots after 30 days
              for old_root in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
                  delete_subvolume_recursively "$old_root"
              done

              # Create new root subvolume
              btrfs subvolume create /btrfs_tmp/${cfg.rootSubvolume}
              umount /btrfs_tmp
            '';
          };
        };
    };
}
