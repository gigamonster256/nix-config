{ self, ... }@flake:
{
  # build this host in CI
  flake.ci.x86_64-linux.nixos = [ "oppie" ];

  configurations.nixos.oppie =
    { ... }:
    {
      imports = with self.modules.nixos; [
        facter
        disko
        minimal
        node_exporter
        router
      ];

      # stable names for the 6x intel i226-v ports (see README for the port map)
      systemd.network.links = {
        "10-enmg0" = {
          matchConfig.MACAddress = "34:1a:4c:04:10:0d";
          linkConfig.Name = "enmg0";
        };
        "10-enmg1" = {
          matchConfig.MACAddress = "34:1a:4c:04:10:0e";
          linkConfig.Name = "enmg1";
        };
        "10-enmg2" = {
          matchConfig.MACAddress = "34:1a:4c:04:10:0f";
          linkConfig.Name = "enmg2";
        };
        "10-enmg3" = {
          matchConfig.MACAddress = "34:1a:4c:04:10:10";
          linkConfig.Name = "enmg3";
        };
        "10-enmg4" = {
          matchConfig.MACAddress = "34:1a:4c:04:10:11";
          linkConfig.Name = "enmg4";
        };
        "10-enmg5" = {
          matchConfig.MACAddress = "34:1a:4c:04:10:12";
          linkConfig.Name = "enmg5";
        };
      };

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
        # NOTE: vlan ids assumed to match the 3rd octet of each subnet
        lanVlans = [
          {
            vlanId = 12;
            address = "172.16.12.1/24";
            description = "main lan";
            # native vlan - untagged on the trunk port
            untagged = true;
          }
          {
            vlanId = 15;
            address = "172.16.15.1/24";
            description = "servers";
          }
          {
            vlanId = 17;
            address = "172.16.17.1/24";
            description = "iot";
          }
          {
            vlanId = 13;
            address = "172.16.13.1/24";
            description = "vpn egress lan";
            # TODO: wireguard interface for vpn egress (needs keys/secrets)
            egressInterface = "wg-vpn";
          }
        ];
        # node_exporter scrapeable from LANs
        lanOpenTcpPorts = [ 9000 ];
      };

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
