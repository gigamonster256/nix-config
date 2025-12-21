{
  unify.modules = {
    uptime-kuma.nixos = {
      services.uptime-kuma.enable = true;
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      services.nginx = {
        enable = true;
        virtualHosts."uptime.nortonweb.org" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3001";
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
      lib.mkIf config.services.uptime-kuma.enable {
        # FIXME: unify the backup directories based on a nixos option
        systemd.services.backup-uptime-kuma = {
          description = "Backup Uptime Kuma data";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.rsync} -a --no-owner --no-group --delete /var/lib/uptime-kuma/ /mnt/backup/uptime-kuma/";
          };
          requires = [ "mnt-backup.mount" ];
          after = [ "mnt-backup.mount" ];
        };
        systemd.timers.backup-uptime-kuma = {
          description = "Backup of Uptime Kuma data every 8 hours";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 00/8:00:00";
            Persistent = true;
          };
        };
      };
  };
}
