{
  # Extreme Networks X440-48p switch configuration
  # Declarative VLAN config → ExtremeXOS CLI commands
  #
  # Build:
  #   nix build .#extreme-switch-vlan-config
  #   cat result

  packages.extreme-switch-vlan-config =
    {
      lib,
      runCommand,
      python3,
    }:
    let
      switchConfig = {
        networks = {
          Default = {
            tag = 12;
            ipv6 = {
              address = "2001:470:b8c5::2/64";
              linkLocal = true;
            };
          };
          Network = {
            tag = 100;
            ipv4 = {
              address = "172.16.100.2";
              netmask = "255.255.255.0";
            };
            ipv6 = {
              address = "2001:470:b8c5:402::2/64";
              linkLocal = true;
            };
          };
          PenguinVPN.tag = 13;
          PPIoT.tag = 17;
          Servers.tag = 15;
          Mgmt.ipv4 = {
            address = "192.168.1.1";
            netmask = "255.255.255.0";
          };
        };

        maxPorts = 48;

        routes = {
          default = "172.16.100.1";
        };

        dnsServers = [
          "172.16.15.50"
          "172.16.15.51"
        ];

        devices = {
          # Network devices
          u6-lite = {
            port = 1;
            untagged = "Network";
            tagged = [
              "Default"
              "PenguinVPN"
              "PPIoT"
            ];
          };
          uap-ac-lite = {
            port = 2;
            untagged = "Network";
            tagged = [
              "Default"
              "PenguinVPN"
              "PPIoT"
            ];
          };
          udm-pro-lan = {
            port = 37;
            untagged = "Network";
            tagged = [
              "Default"
              "PenguinVPN"
              "PPIoT"
            ];
          };

          # Servers
          wyse-switch = {
            port = 3;
            untagged = "Servers";
          };
          tinyca = {
            port = 43;
            untagged = "Servers";
          };

          # Multi-purpose access + trunk
          sem-eth0 = {
            port = 27;
            untagged = "Servers";
            tagged = [
              "PenguinVPN"
              "PPIoT"
            ];
          };
          fatman = {
            port = 44;
            untagged = "Servers";
            tagged = [ "PenguinVPN" ];
          };

          # trunk from main network
          sem-eth1 = {
            port = 29;
            untagged = "Default";
            tagged = [
              "Network"
              "PenguinVPN"
              "PPIoT"
              "Servers"
            ];
          };

          # Default access ports
          spare-1 = {
            port = 45;
            untagged = "Default";
          };
          dock = {
            port = 46;
            untagged = "Default";
          };
          udm-pro-wan = {
            port = 47;
            untagged = "Default";
          };
        };
      };
    in
    runCommand "extreme-switch-vlan-config" { } ''
      echo '${builtins.toJSON switchConfig}' | ${lib.getExe python3} ${./generate-config.py} > $out
    '';
}
