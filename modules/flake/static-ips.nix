{ lib, ... }:
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
      # subnets share much of the same configuration
      mkSubnet =
        {
          ipv4Prefix ? null,
          ipv4PrefixLength ? 24,
          ipv4Gateway ? null,
          ipv6Prefix ? null,
          ipv6PrefixLength ? 64,
          ipv6Gateway ? null,
          dns ? [ ],
        }:
        interface: suffixes: extraConfig:
        {
          inherit interface dns;
          ipv4 = lib.mapNullable (prefix: {
            address = prefix + suffixes.ipv4;
            prefixLength = ipv4PrefixLength;
            gateway = ipv4Gateway;
          }) ipv4Prefix;
          ipv6 = lib.mapNullable (prefix: {
            address = prefix + suffixes.ipv6;
            prefixLength = ipv6PrefixLength;
            gateway = ipv6Gateway;
          }) ipv6Prefix;
        }
        // extraConfig;

      # Server subnet
      mkServerHost = mkSubnet {
        ipv4Prefix = "172.16.15.";
        ipv4PrefixLength = 24;
        ipv4Gateway = "172.16.15.1";
        ipv6Prefix = "2001:470:b8c5:400::";
        ipv6PrefixLength = 64;
        ipv6Gateway = "fe80::aab8:e0ff:fe00:e184";
        dns = [
          "172.16.15.50#ns1.nortonweb.org"
          "172.16.15.51#ns2.nortonweb.org"
          "2001:470:b8c5:400::50#ns1.nortonweb.org"
          "2001:470:b8c5:400::51#ns2.nortonweb.org"
        ];
      };

      # servers share the same suffix
      mkServer =
        interface: suffix:
        mkServerHost interface {
          ipv4 = suffix;
          ipv6 = suffix;
        };

      # Wyse hosts use enp1s0
      mkWyse = mkServer "enp1s0";
    in
    {
      # dns servers should only have static (no dynamic privacy/mngtmpaddr addresses)
      wyse-DX = mkWyse "50" {
        networkConfig = {
          IPv6PrivacyExtensions = false;
          IPv6AcceptRA = false;
        };
      };
      wyse-CW = mkWyse "51" {
        networkConfig = {
          IPv6PrivacyExtensions = false;
          IPv6AcceptRA = false;
        };
      };

      wyse-91 = mkWyse "52" { };
      wyse-F8 = mkWyse "53" { };
      wyse-F4 = mkWyse "54" { };
      tinyca = mkServer "enu1u1u1" "20" { };
    };
}
