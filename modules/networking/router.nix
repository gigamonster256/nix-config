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
#
# Optional extras (see options):
#   router.heTunnel - Hurricane Electric 6in4 tunnel for ISPs without IPv6.
#       Carves per-VLAN /64s out of the routed /48 (mirroring the ULA
#       scheme) and keeps the tunnel endpoint fresh via a sops-backed
#       dyn-DNS updater service.
#   router.nat64    - tayga NAT64 (for use with a DNS64 resolver) on the
#       well-known or a custom prefix.
{
  flake.modules.nixos.router =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib) types;
      cfg = config.router;
      heCfg = cfg.heTunnel;
      nat64Cfg = cfg.nat64;
      heEnabled = heCfg.enable;
      nat64Enabled = nat64Cfg.enable;

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

      # per-VLAN GUA /64 carved out of the HE routed /48 (same scheme as ULA)
      vlanHe = vlan: "${heCfg.routedPrefix}:${lib.toLower (lib.toHexString vlan.vlanId)}::/64";

      # DHCPv6-PD SubnetId as networkd expects it (hex, unique per VLAN)
      vlanSubnetId = vlan: "0x" + lib.toUpper (lib.toHexString vlan.vlanId);

      # LANs which egress out the WAN vs a dedicated interface (e.g. wireguard)
      wanLans = lib.filter (vlan: vlan.egressInterface == null) cfg.lanVlans;
      tunneledLans = lib.filter (vlan: vlan.egressInterface != null) cfg.lanVlans;

      quotedList = xs: "{ ${lib.concatMapStringsSep ", " (x: ''"${x}"'') xs} }";
      portList = ports: "{ ${lib.concatMapStringsSep ", " toString ports} }";

      portForwardType = types.submodule {
        options = {
          protocol = lib.mkOption {
            type = types.enum [
              "tcp"
              "udp"
              "both"
            ];
            default = "tcp";
            description = "L4 protocol to forward.";
          };
          listenPort = lib.mkOption {
            type = types.port;
            description = "Destination port on the router's own LAN addresses.";
          };
          targetIP = lib.mkOption {
            type = types.str;
            description = "LAN IP to DNAT to (e.g. from network-topology allocations).";
          };
          targetPort = lib.mkOption {
            type = types.nullOr types.port;
            default = null;
            description = "Destination port on the target; null = same as listenPort.";
          };
          description = lib.mkOption {
            type = types.str;
            default = "";
            description = "Comment rendered above the nft rule.";
          };
        };
      };

      # gateway IPs (no prefix length) so DNAT only intercepts traffic
      # addressed to the router itself, not host-to-host traffic.
      gatewayIP = vlan: lib.head (lib.splitString "/" vlan.address);
      gatewayIPs = map gatewayIP cfg.lanVlans;

      nftProtoLines =
        fw:
        let
          protos =
            if fw.protocol == "both" then
              [
                "tcp"
                "udp"
              ]
            else
              [ fw.protocol ];
          dstPort = if fw.targetPort == null then fw.listenPort else fw.targetPort;
        in
        lib.concatMapStrings (proto: ''
          ${lib.optionalString (fw.description != "") "# ${fw.description}"}
          iifname ${quotedList lanIfaces} ip daddr { ${lib.concatStringsSep ", " gatewayIPs} } ${proto} dport ${toString fw.listenPort} dnat to ${fw.targetIP}:${toString dstPort}
        '') protos;

      taygaConf = pkgs.writeText "tayga.conf" ''
        tun-device ${nat64Cfg.tunDevice}
        ipv4-addr ${nat64Cfg.ipv4Address}
        ${lib.optionalString (nat64Cfg.ipv6Address != null) "ipv6-addr ${nat64Cfg.ipv6Address}"}
        prefix ${nat64Cfg.prefix}
        dynamic-pool ${nat64Cfg.ipv4Pool}
        data-dir /var/lib/tayga
      '';

      # Polls HE's Dyn-compliant endpoint API; HE auto-detects our IPv4
      # from the connection when myip is omitted. Credentials come from
      # an EnvironmentFile (sops template) with HE_USERNAME/HE_PASSWORD/
      # HE_TUNNEL_ID. Responses: "good <ip>" | "nochg <ip>" on success.
      heUpdateScript = pkgs.writeShellScript "he-tunnel-update" ''
        set -eu
        : "''${HE_USERNAME:?HE_USERNAME not set}"
        : "''${HE_PASSWORD:?HE_PASSWORD not set}"
        : "''${HE_TUNNEL_ID:?HE_TUNNEL_ID not set}"
        resp="$(${lib.getExe pkgs.curl} --fail --silent --show-error --get \
          https://ipv4.tunnelbroker.net/nic/update \
          --data-urlencode "username=$HE_USERNAME" \
          --data-urlencode "password=$HE_PASSWORD" \
          --data-urlencode "hostname=$HE_TUNNEL_ID")"
        echo "HE tunnel update response: $resp"
        case "$resp" in
          good* | nochg*) exit 0 ;;
          *)
            echo "HE tunnel update failed: $resp" >&2
            exit 1
            ;;
        esac
      '';

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
            ${
              if heEnabled then
                ''
                  # 6in4 tunnel - only from the HE server
                  iifname "${cfg.wanInterface}" ip protocol 41 ip saddr ${heCfg.serverIPv4} accept
                ''
              else
                ''
                  # 6in4 (e.g. hurricane electric tunnel)
                  ip6 nexthdr 41 accept
                ''
            }

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
            ${lib.optionalString heEnabled ''
              #
              # LAN -> HE tunnel (IPv6 default route egresses here)
              #
              ${lib.concatMapStrings (vlan: ''
                iifname "${vlanIf vlan}" oifname "${heCfg.interfaceName}" accept
              '') wanLans}
            ''}
            ${lib.optionalString nat64Enabled ''
              #
              # LAN <-> NAT64 (client v6 in, translated v4 out to WAN,
              # translated v6 replies back to LANs)
              #
              iifname ${quotedList lanIfaces} oifname "${nat64Cfg.tunDevice}" accept
              iifname "${nat64Cfg.tunDevice}" oifname "${cfg.wanInterface}" accept
              iifname "${nat64Cfg.tunDevice}" oifname ${quotedList lanIfaces} accept
            ''}

            #
            # Tunneled LANs (vpn-only egress)
            #
            ${lib.concatMapStrings (vlan: ''
              iifname "${vlanIf vlan}" oifname "${vlan.egressInterface}" accept
            '') tunneledLans}
            ${lib.optionalString (cfg.portForwards != [ ]) ''
              #
              # Port forwards (DNAT): allow already-dNATed traffic on to LAN targets
              # (direct LAN<->LAN traffic stays dropped)
              #
              iifname ${quotedList lanIfaces} oifname ${quotedList lanIfaces} ct status dnat accept
            ''}
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
          # (only traffic addressed to the router itself is intercepted;
          # direct host-to-host traffic is untouched)
          chain prerouting {
            type nat hook prerouting priority dstnat;
            policy accept;

            ${lib.concatMapStrings nftProtoLines cfg.portForwards}
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
        ipv6Prefixes = [
          {
            Prefix = vlanUla vlan;
            Assign = true;
          }
        ]
        # globally-routable /64 from the HE routed /48, same vlan-hex scheme
        ++ lib.optional heEnabled {
          Prefix = vlanHe vlan;
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
            type = lib.types.listOf lib.types.int;
            default = [ ];
            description = "UDP ports reachable on the router from LANs.";
          };
          portForwards = lib.mkOption {
            type = lib.types.listOf portForwardType;
            default = [ ];
            description = ''
              IPv4 DNAT port forwards from the router's own LAN addresses to LAN
              targets (e.g. oppie acting as reverse-proxy front: DNS points a
              name at oppie, oppie forwards the port to the backend).
              Only packets addressed to the router are intercepted; direct
              host-to-host traffic is untouched. Forwarded traffic is accepted
              in the forward chain via ct status dnat; LAN<->LAN isolation is
              otherwise preserved.
            '';
            example = [
              {
                protocol = "tcp";
                listenPort = 443;
                targetIP = "172.16.15.53";
                description = "grafana via oppie";
              }
            ];
          };
          heTunnel = {
            enable = lib.mkEnableOption "Hurricane Electric 6in4 tunnel (for ISPs without IPv6).";
            interfaceName = lib.mkOption {
              type = types.str;
              default = "he-6in4";
              description = "Name of the SIT tunnel interface.";
            };
            serverIPv4 = lib.mkOption {
              type = types.str;
              example = "184.105.253.10";
              description = "HE tunnel server IPv4 address (Tunnel Endpoints on tunnelbroker.net).";
            };
            clientIPv6 = lib.mkOption {
              type = types.str;
              example = "2001:470:1f0e:16c::2/64";
              description = "HE tunnel client IPv6 address in CIDR notation.";
            };
            serverIPv6 = lib.mkOption {
              type = types.str;
              example = "2001:470:1f0e:16c::1";
              description = "HE tunnel server IPv6 address (default gateway for ::/0).";
            };
            routedPrefix = lib.mkOption {
              type = types.str;
              example = "2001:470:b8c5";
              description = "HE routed /48 base (first 3 hextets); per-VLAN /64s mirror the ULA vlan-hex scheme.";
            };
            tunnelId = lib.mkOption {
              type = types.str;
              example = "925714";
              description = "Numeric HE tunnel ID used as hostname in endpoint updates.";
            };
            credentialsFile = lib.mkOption {
              type = types.nullOr types.path;
              default = null;
              description = ''
                EnvironmentFile with HE_USERNAME, HE_PASSWORD (tunnel update key
                if set, else account password) and HE_TUNNEL_ID. Null disables
                the updater service. Intended to be a sops template path.
              '';
            };
            updateInterval = lib.mkOption {
              type = types.str;
              default = "5min";
              description = "How often to refresh the HE IPv4 endpoint (systemd OnUnitActiveSec).";
            };
          };
          nat64 = {
            enable = lib.mkEnableOption "tayga NAT64 (for use with a DNS64 resolver).";
            tunDevice = lib.mkOption {
              type = types.str;
              default = "nat64";
              description = "Name of the TUN device tayga translates through.";
            };
            prefix = lib.mkOption {
              type = types.str;
              default = "64:ff9b::/96";
              description = "NAT64 prefix. Must match what the DNS64 resolver synthesizes.";
            };
            ipv4Pool = lib.mkOption {
              type = types.str;
              default = "192.168.255.0/24";
              description = "IPv4 dynamic pool tayga translates into (masqueraded out the WAN).";
            };
            ipv4Address = lib.mkOption {
              type = types.str;
              default = "192.168.255.1";
              description = "tayga's own IPv4 address (tayga ipv4-addr).";
            };
            ipv6Address = lib.mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "fd45:84c0:0f60:64::1";
              description = "tayga's own IPv6 address (tayga ipv6-addr), e.g. a ULA outside the LAN /64s.";
            };
            package = lib.mkOption {
              type = types.package;
              default = pkgs.tayga;
              description = "tayga package (defaults to the overlaid apalrd fork).";
            };
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
        assertions = [
          {
            assertion = lib.length untaggedLans <= 1;
            message = "router: at most one lanVlans entry may set untagged = true";
          }
          {
            assertion = cfg.portForwards == [ ] || cfg.lanVlans != [ ];
            message = "router: portForwards need at least one lanVlans entry (gateway IPs to intercept)";
          }
        ];

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
          )
          # HE 6in4 tunnel endpoint (client /64 + default v6 route via HE)
          // lib.optionalAttrs heEnabled {
            "20-${heCfg.interfaceName}" = {
              matchConfig.Name = heCfg.interfaceName;
              address = [ heCfg.clientIPv6 ];
              networkConfig = {
                Description = "Hurricane Electric 6in4 tunnel";
                DHCP = "no";
                IPv6AcceptRA = false;
              };
              routes = lib.singleton {
                Destination = "::/0";
                Gateway = heCfg.serverIPv6;
                GatewayOnLink = true;
                Metric = 100;
              };
            };
          }
          # NAT64 TUN device (pool + prefix routed into tayga)
          // lib.optionalAttrs nat64Enabled {
            "40-${nat64Cfg.tunDevice}" = {
              matchConfig.Name = nat64Cfg.tunDevice;
              address = [
                "${nat64Cfg.ipv4Address}/${lib.last (lib.splitString "/" nat64Cfg.ipv4Pool)}"
              ]
              ++ lib.optional (nat64Cfg.ipv6Address != null) "${nat64Cfg.ipv6Address}/64";
              networkConfig = {
                Description = "tayga NAT64";
                DHCP = "no";
                IPv6AcceptRA = false;
              };
              routes = lib.singleton {
                Destination = nat64Cfg.prefix;
              };
            };
          };

          netdevs =
            lib.listToAttrs (map (vlan: lib.nameValuePair (vlanIf vlan) (vlanNetdev vlan)) taggedLans)
            # SIT tunnel; Local intentionally unset so a dynamic WAN IPv4
            # keeps working (HE side follows via the updater service)
            // lib.optionalAttrs heEnabled {
              ${heCfg.interfaceName} = {
                netdevConfig = {
                  Name = heCfg.interfaceName;
                  Kind = "sit";
                  MTUBytes = "1480";
                };
                tunnelConfig = {
                  Remote = heCfg.serverIPv4;
                  TTL = 255;
                };
              };
            }
            // lib.optionalAttrs nat64Enabled {
              ${nat64Cfg.tunDevice} = {
                netdevConfig = {
                  Name = nat64Cfg.tunDevice;
                  Kind = "tun";
                };
                tunConfig = {
                  User = "root";
                  Group = "root";
                };
              };
            };
        };

        # use the LAN resolvers for the router's own lookups
        services.resolved = {
          enable = true;
          settings.Resolve = lib.optionalAttrs (cfg.dnsServers != [ ]) {
            DNS = cfg.dnsServers;
            DNSOverTLS = "opportunistic";
          };
        };

        # tayga NAT64 daemon (TUN device is pre-created by networkd above)
        systemd.services.tayga = lib.mkIf nat64Enabled {
          description = "tayga stateless NAT64";
          wantedBy = [ "multi-user.target" ];
          after = [ "systemd-networkd.service" ];
          wants = [ "systemd-networkd.service" ];
          serviceConfig = {
            ExecStart = "${lib.getExe nat64Cfg.package} -d --nodetach --config ${taygaConf}";
            ExecReload = "${lib.getExe' pkgs.coreutils "kill"} -SIGHUP $MAINPID";
            Restart = "always";
            RestartSec = 5;
            StateDirectory = "tayga";
          };
        };

        # keeps the HE tunnel's client IPv4 endpoint current (dynamic WAN IP)
        systemd.services.he-tunnel-update = lib.mkIf (heEnabled && heCfg.credentialsFile != null) {
          description = "Update HE tunnelbroker IPv4 endpoint";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          environment.SSL_CERT_FILE = config.security.pki.caBundle;
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = heCfg.credentialsFile;
            ExecStart = heUpdateScript;
          };
        };
        systemd.timers.he-tunnel-update = lib.mkIf (heEnabled && heCfg.credentialsFile != null) {
          description = "Refresh HE tunnelbroker IPv4 endpoint";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2min";
            OnUnitActiveSec = heCfg.updateInterval;
          };
        };
      };
    };
}
