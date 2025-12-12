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
          firewallTCPPorts = [
            53 # DNS over TCP
            853 # DNS over TLS
            5380 # Technitium web interface
            53443 # Technitium web interface over HTTPS
          ];
        };

        # ACME certificate using HTTP challenge
        security.acme = {
          acceptTerms = true;
          defaults = {
            email = "admin@nortonweb.org";
            server = "https://certs.nortonweb.org/acme/acme/directory";
            webroot = "/var/lib/acme/acme-challenge";
            renewInterval = "*-*-* 00/12:00:00";
          };
          certs.${config.services.technitium-dns-server.hostName} = {
            # technitium likes to have the cert in pfx format
            # place it in the technitium dns server directory (private DynamicUser access)
            postRun = ''
              ${lib.getExe pkgs.openssl} pkcs12 -export -out "/var/lib/technitium-dns-server/tls.pfx" -inkey "key.pem" -in "cert.pem" -certfile "chain.pem" -keypbe NONE -certpbe NONE -passout pass:
              chown nobody:nogroup "/var/lib/technitium-dns-server/tls.pfx"
            '';
          };
        };

        # run nginx to serve ACME challenges
        users.users.nginx.extraGroups = [ "acme" ];
        services.nginx = {
          enable = true;
          virtualHosts = {
            ${config.services.technitium-dns-server.hostName} = {
              # Catchall vhost, will redirect users to HTTPS for all vhosts
              # serverAliases = [ "*.example.com" ];
              locations."/.well-known/acme-challenge" = {
                root = config.security.acme.defaults.webroot;
              };
              # locations."/" = {
              #   return = "301 https://$host$request_uri";
              # };
            };
          };
        };

        # open port 80 for ACME HTTP challenge
        networking.firewall.allowedTCPPorts = [ 80 ];

        # disable systemd-resolved to avoid conflicts with technitium dns server
        services.resolved.enable = false;
      };
  };
}
