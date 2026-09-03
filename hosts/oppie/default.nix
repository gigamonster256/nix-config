{ self, ... }@flake:
{
  # build this host in CI
  flake.ci.x86_64-linux.nixos = [ "oppie" ];

  configurations.nixos.oppie =
    { lib, ... }:
    {
      imports = with self.modules.nixos; [
        facter
        disko
        minimal
        node_exporter
        router
        oppie-dns
        oppie-proxy
      ];

      # stable names for the 6x intel i226-v ports (see README for the port map)
      systemd.network.links =
        let
          link = name: hex: {
            matchConfig.MACAddress = "34:1a:4c:04:10:${hex}";
            linkConfig.Name = name;
          };
          interfaces = {
            enmg0 = "0d";
            enmg1 = "0e";
            enmg2 = "0f";
            enmg3 = "10";
            enmg4 = "11";
            enmg5 = "12";
          };
        in
        lib.mapAttrs' (name: hex: lib.nameValuePair "10-${name}" (link name hex)) interfaces;

      # apalrd-style systemd-networkd router
      # https://www.apalrd.net/posts/2026/asn_networkd/
      router = {
        enable = true;
        wanInterface = "enmg0";
        lanTrunkInterface = "enmg1";
        backupInterface = "enmg5";
        # ns1/ns2 (technitium on wyse-DX / wyse-CW)
        dnsServers = [
          "172.16.15.50"
          "172.16.15.51"
        ];
        ulaPrefix = "fd45:84c0:0f60";
        # VLANs/addresses come from network-topology (single source with DNS);
        # NOTE: vlan ids must match the 3rd octet of each subnet.
        lanVlans = flake.config.network-topology.routerVlans;
        # node_exporter scrapeable from LANs
        lanOpenTcpPorts = [ 9000 ];

        # ISP has no IPv6 - Hurricane Electric 6in4 (tunnel 925714)
        heTunnel = {
          enable = true;
          serverIPv4 = "184.105.253.10";
          clientIPv6 = "2001:470:1f0e:16c::2/64";
          serverIPv6 = "2001:470:1f0e:16c::1";
          routedPrefix = "2001:470:b8c5";
          tunnelId = "925714";
          # TODO(bootstrap): point at sops template once hosts/oppie/secrets.yaml
          # exists (see README) - until then the endpoint updater is disabled
          # and the tunnel follows HE's cached endpoint.
          # credentialsFile = config.sops.templates."he-tunnel-env".path;
          credentialsFile = null;
        };

        # NAT64 for the DNS64 resolvers (ns1/ns2 synthesize 64:ff9b::/96)
        nat64 = {
          enable = true;
          prefix = "64:ff9b::/96";
          # ULA outside the per-VLAN /64s (vlan hex ids live in :<hex>::)
          ipv6Address = "fd45:84c0:0f60:64::1";
        };
      };

      # TODO(bootstrap): HE tunnelbroker endpoint-update credentials.
      # Uncomment after creating hosts/oppie/secrets.yaml (see README).
      # sops.secrets."he/username" = { };
      # sops.secrets."he/password" = { };
      # sops.templates."he-tunnel-env".content = ''
      #   HE_USERNAME=${config.sops.placeholder."he/username"}
      #   HE_PASSWORD=${config.sops.placeholder."he/password"}
      #   HE_TUNNEL_ID=925714
      # '';

      # discoverable as oppie.local (also via the backup port)
      services.avahi = {
        enable = true;
        publish = {
          enable = true;
          addresses = true;
        };
      };

      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keys = flake.config.meta.owner.sshKeys;

      boot.loader.systemd-boot.configurationLimit = 7;
      nix.gc.automatic = true;

      system.stateVersion = "26.05";
    };
}
