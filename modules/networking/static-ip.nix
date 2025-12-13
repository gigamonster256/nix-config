flake: {
  unify.nixos =
    { lib, config, ... }:
    let
      inherit (lib)
        mkIf
        optional
        ;
      hostname = config.networking.hostName;
      hasStaticIp = flake.config.static-ips ? ${hostname};
      ip = flake.config.static-ips.${hostname};

      # Build address list in CIDR notation
      mkAddress = cfg: optional (cfg != null) "${cfg.address}/${toString cfg.prefixLength}";

      # Build route for gateway
      mkGatewayRoute = cfg: optional (cfg != null && cfg.gateway != null) { Gateway = cfg.gateway; };
    in
    mkIf hasStaticIp {
      # Use systemd-networkd
      systemd.network = {
        enable = true;
        networks."10-${ip.interface}" = {
          matchConfig.Name = ip.interface;

          # Addresses in CIDR notation
          address = mkAddress ip.ipv4 ++ mkAddress ip.ipv6;

          # Gateway routes
          routes = mkGatewayRoute ip.ipv4 ++ mkGatewayRoute ip.ipv6;

          # DNS servers
          networkConfig = {
            DNS = ip.dns;
          }
          // ip.networkConfig;

          inherit (ip) linkConfig;
        };
      };

      # Disable legacy networking DHCP
      networking.useDHCP = false;

      # assume that if we're using static IPs, we are on the home network
      # and can do DoT and DNSSEC to local resolvers
      services.resolved = {
        dnsovertls = "opportunistic";
        # dnssec = "allow-downgrade";
      };
    };
}
