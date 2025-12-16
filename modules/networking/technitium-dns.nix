{
  unify.nixos =
    { lib, config, ... }:
    {
      options = {
        services.technitium-dns-server = {
          hostName = lib.mkOption {
            type = lib.types.str;
            default = config.networking.hostName;
            description = "The hostname for the Technitium DNS server.";
          };
        };
      };
    };

  unify.modules.technitium-dns = {
    nixos =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        services.technitium-dns-server = {
          enable = lib.mkDefault true;
          openFirewall = true;
          firewallUDPPorts = [
            53 # DNS over UDP
            853 # DNS over QUIC
          ];
          firewallTCPPorts = [
            53 # DNS over TCP
            853 # DNS over TLS
            # 5380 # Technitium web interface
            # 53443 # Technitium web interface over HTTPS
          ];
        };

        # ACME certificate using HTTP challenge
        security.acme = {
          certs.${config.services.technitium-dns-server.hostName} = {
            # technitium likes to have the cert in pfx format for DoT usage
            # place it in the technitium dns server directory (private DynamicUser access)
            postRun = ''
              ${lib.getExe pkgs.openssl} pkcs12 -export -out "/var/lib/technitium-dns-server/tls.pfx" -inkey "key.pem" -in "cert.pem" -certfile "chain.pem" -keypbe NONE -certpbe NONE -passout pass:
              chown nobody:nogroup "/var/lib/technitium-dns-server/tls.pfx"
            '';
          };
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
        services.nginx = {
          enable = true;
          virtualHosts = {
            ${config.services.technitium-dns-server.hostName} = {
              enableACME = true;
              forceSSL = true;
              # TODO: TLS termination is a bit weird - re-think if I enable DoH
              # 53 UDP/TCP regular DNS - no TLS
              # 853 UDP/TCP DoT/DoQ - terminated by technitium
              # 80/443 web interface - TLS terminated by nginx
              # 53443 web interface - TLS terminated by technitium
              locations."/" = {
                proxyPass = "http://127.0.0.1:5380/";
              };
              # TODO: consider enabling DoH in the future
              # locations."/dns-query" = {
              #   proxyPass = "http://127.0.0.1:80/";
              # };
            };
          };
        };

        # disable systemd-resolved to avoid conflicts with technitium dns server
        services.resolved.enable = false;

        # disable tempAddress generation for privacy extensions
        # ensures ips used in zone notification are stable
        networking.tempAddresses = "disabled";

        # TODO: make this better
        # backup technitium dns server data to NFS mount
        backup.fatman.enable = true;
        systemd.services.backup-technitium-dns = {
          description = "Backup Technitium DNS server data";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.rsync} -a --delete /var/lib/technitium-dns-server/ /mnt/backup/technitium-dns/";
          };
          requires = [ "mnt-backup.mount" ];
          after = [ "mnt-backup.mount" ];
        };
        systemd.timers.backup-technitium-dns = {
          description = "Backup of Technitium DNS server data every 8 hours";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 00/8:00:00";
            Persistent = true;
          };
        };
      };
  };
}
