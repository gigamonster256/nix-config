{ lib, config, ... }:
let
  inherit (lib)
    mkOption
    types
    ;

  # Address configuration submodule (used for both ipv4 and ipv6)
  addressType = lib.types.submodule {
    options = {
      address = mkOption {
        type = types.str;
        description = "IP address.";
      };
      prefixLength = mkOption {
        type = types.int;
        description = "Prefix length.";
      };
      gateway = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default gateway address.";
      };
    };
  };

  # Static IP configuration submodule
  staticIpType = types.submodule {
    options = {
      interface = mkOption {
        type = types.str;
        description = "Network interface name.";
      };
      ipv4 = mkOption {
        type = types.nullOr addressType;
        default = null;
        description = "IPv4 configuration.";
      };
      ipv6 = mkOption {
        type = types.nullOr addressType;
        default = null;
        description = "IPv6 configuration.";
      };
      dns = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of DNS servers.";
      };
      networkConfig = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Extra systemd.network networkConfig options.";
      };
      linkConfig = mkOption {
        type = types.attrsOf types.anything;
        default = {
          RequiredForOnline = "routable";
        };
        description = "Extra systemd.network linkConfig options.";
      };
    };
  };
in
{
  options.static-ips = mkOption {
    type = types.attrsOf staticIpType;
    default = { };
    description = "Static IP addresses for hosts in this flake.";
  };

  config.static-ips =
    let
      topo = config.network-topology;

      # Interface/DNS framing stays here; addresses come from
      # network-topology.allocations so vlan/suffix are declared exactly
      # once (in network-topology.hosts).
      mkHost =
        interface: extraConfig: hostname:
        let
          a =
            topo.allocations.${hostname}
              or (throw "static-ips: ${hostname} missing from network-topology.hosts");
        in
        {
          inherit interface;
          ipv4 = {
            address = a.ipv4;
            prefixLength = 24;
            gateway = a.gateway4;
          };
          ipv6 = {
            address = a.ipv6Gua;
            prefixLength = 64;
            gateway = "fe80::aab8:e0ff:fe00:e184";
          };
          dns = [
            "172.16.15.50#ns1.nortonweb.org"
            "172.16.15.51#ns2.nortonweb.org"
            "2001:470:b8c5:f::50#ns1.nortonweb.org"
            "2001:470:b8c5:f::51#ns2.nortonweb.org"
          ];
        }
        // extraConfig;

      # Wyse hosts use enp1s0
      mkWyse = mkHost "enp1s0";
    in
    {
      # dns servers should only have static (no dynamic privacy/mngtmpaddr addresses)
      wyse-DX = mkWyse {
        networkConfig = {
          IPv6PrivacyExtensions = false;
          IPv6AcceptRA = false;
        };
      } "wyse-DX";
      wyse-CW = mkWyse {
        networkConfig = {
          IPv6PrivacyExtensions = false;
          IPv6AcceptRA = false;
        };
      } "wyse-CW";

      wyse-91 = mkWyse { } "wyse-91";
      wyse-F8 = mkWyse { } "wyse-F8";
      wyse-F4 = mkWyse { } "wyse-F4";
      tinyca = mkHost "enu1u1u1" { } "tinyca";
    };
}
