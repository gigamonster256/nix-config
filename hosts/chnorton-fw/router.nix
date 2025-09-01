{ ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.disable_ipv6" = true;
  };

  networking = {
    useDHCP = false;
    nameservers = [ "1.1.1.1" ];
    interfaces = {
      wlp192s0.useDHCP = true;

      # LAN - offering internet to OPNsense
      eth0 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "10.238.192.1";
            prefixLength = 24;
          }
        ];
      };
    };

    nat.enable = false;
    firewall.enable = false;
    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          # enable flow offloading for better throughput
          # flowtable f {
          #   hook ingress priority 0;
          #   devices = { wlp192s0, eth0 };
          # }

          chain output {
            type filter hook output priority 100; policy accept;
          }

          chain input {
            type filter hook input priority filter; policy drop;

            # Allow trusted networks to access the router
            iifname {
              "eth0",
            } counter accept

            # Allow returning traffic from ppp0 and drop everthing else
            iifname "wlp192s0" ct state { established, related } counter accept
            iifname "wlp192s0" drop
          }

          chain forward {
            type filter hook forward priority filter; policy drop;

            # enable flow offloading for better throughput
            # ip protocol { tcp, udp } flow offload @f

            # Allow trusted network WAN access
            iifname {
                    "eth0",
            } oifname {
                    "wlp192s0",
            } counter accept comment "Allow trusted LAN to WAN"

            # Allow established WAN to return
            iifname {
                    "wlp192s0",
            } oifname {
                    "eth0",
            } ct state established,related counter accept comment "Allow established back to LANs"
          }
        }

        table ip nat {
          chain prerouting {
            type nat hook prerouting priority filter; policy accept;
          }

          # Setup NAT masquerading on the ppp0 interface
          chain postrouting {
            type nat hook postrouting priority filter; policy accept;
            oifname "wlp192s0" masquerade
          }
        }
      '';
    };
  };
}
