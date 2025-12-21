{
  unify.modules = {
    radicle = {
      nixos =
        { lib, config, ... }:
        {
          services.nginx.enable = true;
          services.radicle = {
            enable = true;
            node.openFirewall = true;
            settings.node = {
              seedingPolicy = {
                # imperatively follow my nodes
                default = "block";
              };
            };
            httpd = {
              enable = true;
              nginx = {
                serverName = lib.mkDefault config.services.radicle.settings.node.alias;
                # mkMerge isnt working for some reason
                # https://github.com/NixOS/nixpkgs/blob/c6245e83d836d0433170a16eb185cefe0572f8b8/nixos/modules/services/misc/radicle.nix#L388
                enableACME = true;
                forceSSL = true;
              };
            };
          };
          networking.firewall.allowedTCPPorts = [
            80
            443
          ];
        };
      home = {
        programs.radicle = {
          enable = true;
          settings = {
            cli.hints = true;
            node.alias = "gigamonster256";
            preferredSeeds = [
              "z6Mkr2TA8yvN1Z5JahQbdm2iC4ge2vvEEsN1PjwVJV97vYrZ@rad1.nortonweb.org:8776"
              "z6MkrLMMsiPWUcNPHcRajuMi9mDfYckSoJyPwwnknocNYPm7@iris.radicle.xyz:8776"
              "z6MkrLMMsiPWUcNPHcRajuMi9mDfYckSoJyPwwnknocNYPm7@2a01:4f9:c010:dfaa::1:8776"
              "z6MkrLMMsiPWUcNPHcRajuMi9mDfYckSoJyPwwnknocNYPm7@95.217.156.6:8776"
              # "z6MkrLMMsiPWUcNPHcRajuMi9mDfYckSoJyPwwnknocNYPm7@irisradizskwweumpydlj4oammoshkxxjur3ztcmo7cou5emc6s5lfid.onion:8776"
              "z6Mkmqogy2qEM2ummccUthFEaaHvyYmYBYh3dbe9W4ebScxo@rosa.radicle.xyz:8776"
              "z6Mkmqogy2qEM2ummccUthFEaaHvyYmYBYh3dbe9W4ebScxo@2a01:4ff:f0:abd3::1:8776"
              "z6Mkmqogy2qEM2ummccUthFEaaHvyYmYBYh3dbe9W4ebScxo@5.161.85.124:8776"
              # "z6Mkmqogy2qEM2ummccUthFEaaHvyYmYBYh3dbe9W4ebScxo@rosarad5bxgdlgjnzzjygnsxrwxmoaj4vn7xinlstwglxvyt64jlnhyd.onion:8776"
            ];
          };
        };
      };
    };

    backup.nixos =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      # FIXME: only backup config, not the repos themselves?
      lib.mkIf config.services.radicle.enable {
        # FIXME: unify the backup directories based on a nixos option
        systemd.services.backup-radicle = {
          description = "Backup Radicle data";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.rsync} -a --no-owner --no-group --delete /var/lib/radicle/ /mnt/backup/radicle/";
          };
          requires = [ "mnt-backup.mount" ];
          after = [ "mnt-backup.mount" ];
        };
        systemd.timers.backup-radicle = {
          description = "Backup of Radicle data every 8 hours";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 00/8:00:00";
            Persistent = true;
          };
        };
      };
  };

  persistence.programs.homeManager = {
    radicle = {
      directories = [ ".radicle" ];
    };
  };
}
