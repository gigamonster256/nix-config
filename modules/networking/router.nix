# Systemd-networkd based router, adapted from apalrd's design:
# https://www.apalrd.net/posts/2026/asn_networkd/
#
# Topology:
#   wanInterface      - upstream (DHCPv4 + DHCPv6 with prefix delegation)
#   lanTrunkInterface - carries one VLAN per entry in lanVlans
#   backupInterface   - always-up port with its own ULA for outage access
#
# IPv4: nftables stateful firewall + masquerade on WAN (and any tunneled
#       egress interface).
# IPv6: each LAN advertises a ULA /64 (always reachable via NAT66) plus any
#       delegated prefix from the WAN, assigned by SubnetId; the backup port
#       advertises a ULA with RouterLifetimeSec=0 so it never routes.
{
  flake.modules.nixos.router =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib) types;
      cfg = config.router;

      lanType = types.submodule {
        options = {
          vlanId = lib.mkOption {
            type = types.int;
            description = "VLAN id used for both the L2 tag and the DHCPv6-PD SubnetId.";
          };
          address = lib.mkOption {
            type = types.str;
            description = "IPv4 gateway address of this LAN in CIDR notation.";
          };
          description = lib.mkOption {
            type = types.str;
            default = "";
            description = "Description for the network unit.";
          };
          dhcpPoolOffset = lib.mkOption {
            type = types.int;
            default = 100;
            description = "First address of the DHCPv4 pool within the subnet.";
          };
          dhcpPoolSize = lib.mkOption {
            type = types.int;
            default = 100;
            description = "Number of addresses in the DHCPv4 pool.";
          };
          # null means egress directly out the WAN interface.
          # set to a wireguard interface name to force all egress through it.
          egressInterface = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Egress interface for this LAN; null = WAN.";
          };
          # carry this LAN untagged (native vlan) on the trunk interface
          # itself instead of a tagged subinterface. at most one lan can
          # be untagged since a network unit can only match once.
          untagged = lib.mkOption {
            type = types.bool;
            default = false;
            description = "Native (untagged) LAN on the trunk interface.";
          };
        };
      };

      vlanIf =
        vlan:
        if vlan.untagged then cfg.lanTrunkInterface else "${cfg.lanTrunkInterface}.${toString vlan.vlanId}";
      lanIfaces = map vlanIf cfg.lanVlans;

      # subinterfaces only exist for tagged lans
      taggedLans = lib.filter (vlan: !vlan.untagged) cfg.lanVlans;
      untaggedLans = lib.filter (vlan: vlan.untagged) cfg.lanVlans;

      # per-VLAN ULA /64 carved out of the base /48 by the (hex) vlan id
      vlanUla = vlan: "${cfg.ulaPrefix}:${lib.toLower (lib.toHexString vlan.vlanId)}::/64";

      # DHCPv6-PD SubnetId as networkd expects it (hex, unique per VLAN)
      vlanSubnetId = vlan: "0x" + lib.toUpper (lib.toHexString vlan.vlanId);

      # LANs which egress out the WAN vs a dedicated interface (e.g. wireguard)
      wanLans = lib.filter (vlan: vlan.egressInterface == null) cfg.lanVlans;
      tunneledLans = lib.filter (vlan: vlan.egressInterface != null) cfg.lanVlans;

      quotedList = xs: "{ ${lib.concatMapStringsSep ", " (x: ''"${x}"'') xs} }";
      portList = ports: "{ ${lib.concatMapStringsSep ", " toString ports} }";

      ruleset = ''
        flush ruleset

        #
        # IPv4/IPv6 stateful firewall
        #

        table inet filter {

          # INPUT chain is sessions who terminate at this box
          chain input {
            type filter hook input priority filter;
            policy drop;

            # Loopback
            iifname "lo" accept
            ${lib.optionalString (cfg.backupInterface != null) ''
              # Backup interface - always reachable for outage management
              iifname "${cfg.backupInterface}" accept
            ''}

            # Established/related connections
            ct state established,related accept

            # Invalid packets
            ct state invalid drop

            #
            # ICMP (NDP / RA / ping)
            #
            ip protocol icmp accept
            meta l4proto ipv6-icmp accept
            # 6in4 (e.g. hurricane electric tunnel)
            ip6 nexthdr 41 accept

            #
            # DHCP client on WAN
            #
            iifname "${cfg.wanInterface}" udp sport 68 udp dport 67 accept
            iifname "${cfg.wanInterface}" udp sport 546 udp dport 547 accept

            #
            # DHCP server for LANs
            #
            iifname ${quotedList lanIfaces} udp sport 68 udp dport 67 accept
            iifname ${quotedList lanIfaces} udp sport 546 udp dport 547 accept

            #
            # Router administration from LAN (SSH)
            #
            iifname ${quotedList lanIfaces} tcp dport 22 accept
            ${lib.optionalString (cfg.lanOpenTcpPorts != [ ]) ''
              iifname ${quotedList lanIfaces} tcp dport ${portList cfg.lanOpenTcpPorts} accept
            ''}
            ${lib.optionalString (cfg.lanOpenUdpPorts != [ ]) ''
              iifname ${quotedList lanIfaces} udp dport ${portList cfg.lanOpenUdpPorts} accept
            ''}
          }

          # FORWARD chain is where your normal firewall rules go
          # this is stuff that is ROUTED
          chain forward {
            type filter hook forward priority filter;
            policy drop;

            # Established/related connections
            ct state established,related accept

            # Invalid packets
            ct state invalid drop

            #
            # LAN -> WAN
            #
            ${lib.concatMapStrings (vlan: ''
              iifname "${vlanIf vlan}" oifname "${cfg.wanInterface}" accept
            '') wanLans}

            #
            # Tunneled LANs (vpn-only egress)
            #
            ${lib.concatMapStrings (vlan: ''
              iifname "${vlanIf vlan}" oifname "${vlan.egressInterface}" accept
            '') tunneledLans}
          }

          # OUTPUT chain is sessions who are initiated by this box
          chain output {
            type filter hook output priority filter;
            policy accept;
          }
        }


        #
        # IPv4 NAT
        #

        table ip nat {

          # IPv4 Port Forwards go in PREROUTING
          chain prerouting {
            type nat hook prerouting priority dstnat;
            policy accept;

            # iifname "${cfg.wanInterface}" tcp dport 8080 dnat to 10.10.20.150:80
          }

          # MASQUERADE goes in POSTROUTING
          chain postrouting {
            type nat hook postrouting priority srcnat;
            policy accept;

            # IPv4 LAN Internet access
            oifname "${cfg.wanInterface}" masquerade
            ${lib.concatMapStrings (vlan: ''
              oifname "${vlan.egressInterface}" masquerade
            '') tunneledLans}
          }
        }
      '';

      lanNetwork = vlan: {
        matchConfig.Name = vlanIf vlan;
        address = [ vlan.address ];
        networkConfig = {
          Description = vlan.description;
          IPv6SendRA = true;
          IPv6AcceptRA = false;
          DHCPServer = true;
          # NAT66 for the ULA prefixes (delegated prefixes are globally
          # routable and assigned via SubnetId below)
          IPMasquerade = "ipv6";
        };
        dhcpServerConfig = {
          PoolOffset = vlan.dhcpPoolOffset;
          PoolSize = vlan.dhcpPoolSize;
          EmitDNS = cfg.dnsServers != [ ];
          DNS = cfg.dnsServers;
        };
        ipv6SendRAConfig = {
          Managed = false;
          OtherInformation = false;
          RouterLifetimeSec = 1800;
        };
        ipv6Prefixes = lib.singleton {
          Prefix = vlanUla vlan;
          Assign = true;
        };
        dhcpPrefixDelegationConfig = {
          UplinkInterface = cfg.wanInterface;
          SubnetId = vlanSubnetId vlan;
          Announce = true;
          Assign = true;
          # forced suffix - not needed, but some people like it
          Token = "::1";
        };
      };

      vlanNetdev = vlan: {
        enable = true;
        netdevConfig = {
          Name = vlanIf vlan;
          Kind = "vlan";
        };
        vlanConfig.Id = vlan.vlanId;
      };
    in
    {
      options = {
        router = {
          enable = lib.mkEnableOption "systemd-networkd based router/firewall (apalrd-style).";
          wanInterface = lib.mkOption {
            type = types.str;
            description = "Interface connected to the upstream modem (DHCPv4 + DHCPv6-PD).";
          };
          lanTrunkInterface = lib.mkOption {
            type = types.str;
            description = "Interface which carries the configured VLANs as a trunk.";
          };
          backupInterface = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Always-up management interface for outage access (ULA + mDNS only).";
          };
          lanVlans = lib.mkOption {
            type = types.listOf lanType;
            default = [ ];
            description = "LANs carried over the trunk interface as VLANs.";
          };
          dnsServers = lib.mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "DNS servers handed out to LAN clients via DHCPv4 and used by the router itself.";
          };
          ulaPrefix = lib.mkOption {
            type = types.str;
            description = "ULA /48 carved into per-VLAN /64s for IPv6.";
          };
          wanPrefixDelegationHint = lib.mkOption {
            type = types.str;
            default = "::/59";
            description = "DHCPv6-PD hint requested from the upstream router.";
          };
          lanOpenTcpPorts = lib.mkOption {
            type = types.listOf types.int;
            default = [ ];
            description = "TCP ports reachable on the router from LANs (e.g. exporters).";
          };
          lanOpenUdpPorts = lib.mkOption {
            type = types.listOf types.int;
            default = [ ];
            description = "UDP ports reachable on the router from LANs.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        # enable forwarding; accept RA on WAN despite forwarding (accept_ra=2)
        boot.kernel.sysctl = {
          "net.ipv4.conf.all.forwarding" = true;
          "net.ipv6.conf.all.forwarding" = true;
          "net.ipv6.conf.${cfg.wanInterface}.accept_ra" = 2;
        };

        networking = {
          useDHCP = false;
          tempAddresses = "disabled";
          firewall.enable = false;
          nat.enable = false;
          nftables = {
            enable = true;
            inherit ruleset;
          };
        };

        # network units can only match an interface once, so at most one
        # lan can be untagged on the trunk
        assertions = lib.singleton {
          assertion = lib.length untaggedLans <= 1;
          message = "router: at most one lanVlans entry may set untagged = true";
        };

        # no point waiting for a (possibly absent) upstream to boot a router
        systemd.network = {
          enable = true;
          wait-online.enable = false;

          networks = {
            #
            # WAN interface - DHCPv4 client + DHCPv6 client with prefix delegation
            #
            "05-wan" = {
              matchConfig.Name = cfg.wanInterface;
              networkConfig = {
                Description = "WAN";
                # ipv4 via DHCP; ipv6 via RA (DHCPv6Client=always requests PD
                # even when the RA M-flag is not set)
                DHCP = "ipv4";
                IPv6AcceptRA = true;
              };
              dhcpV4Config = {
                UseRoutes = true;
                RouteMetric = 100;
              };
              ipv6AcceptRAConfig = {
                RouteMetric = 100;
                DHCPv6Client = "always";
              };
              dhcpV6Config = {
                # PD hint (ForceDHCPv6PDOtherInformation is deprecated upstream;
                # DHCPv6Client=always above already forces the client to run)
                PrefixDelegationHint = cfg.wanPrefixDelegationHint;
              };
            };

            #
            # LAN trunk - carries tagged VLAN subinterfaces plus the untagged
            # (native) LAN, whose L3 config is folded in directly
            #
            "10-lan-trunk" = lib.mkIf (cfg.lanVlans != [ ]) (
              lib.mkMerge (
                lib.singleton {
                  matchConfig.Name = cfg.lanTrunkInterface;
                  networkConfig = {
                    Description = lib.mkDefault "LAN VLAN trunk";
                    DHCP = "no";
                    IPv6AcceptRA = false;
                    VLAN = map vlanIf taggedLans;
                  };
                }
                # the untagged lan brings its own matchConfig.Name = trunk
                ++ map lanNetwork untaggedLans
              )
            );

            #
            # Backup interface - ULA + mDNS, but never routes
            # (works during internet outages, independent of everything else)
            #
            "06-backup" = lib.mkIf (cfg.backupInterface != null) {
              matchConfig.Name = cfg.backupInterface;
              networkConfig = {
                Description = "Outage management interface";
                IPv6AcceptRA = true;
                IPv6SendRA = true;
                MulticastDNS = true;
              };
              ipv6SendRAConfig = {
                Managed = false;
                OtherInformation = false;
                # not a router!
                RouterLifetimeSec = 0;
              };
              ipv6Prefixes = lib.singleton {
                Prefix = "${cfg.ulaPrefix}:fd::/64";
                Assign = true;
              };
            };
          }
          # per-VLAN LAN networks
          // lib.listToAttrs (
            map (vlan: lib.nameValuePair "30-${vlanIf vlan}" (lanNetwork vlan)) cfg.lanVlans
          );

          netdevs = lib.listToAttrs (
            map (vlan: lib.nameValuePair (vlanIf vlan) (vlanNetdev vlan)) taggedLans
          );
        };

        # use the LAN resolvers for the router's own lookups
        services.resolved = {
          enable = true;
          settings.Resolve = lib.optionalAttrs (cfg.dnsServers != [ ]) {
            DNS = cfg.dnsServers;
            DNSOverTLS = "opportunistic";
          };
        };
      };
    };
}
