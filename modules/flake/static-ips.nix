{ lib, ... }:
{
  options = {
    static-ips = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            address = lib.mkOption {
              type = lib.types.str;
            };
            prefixLength = lib.mkOption {
              type = lib.types.int;
            };
            interface = lib.mkOption {
              type = lib.types.str;
            };
          };
        }
      );
      description = "Static IP addresses for hosts in this flake.";
    };
  };

  config = {
    static-ips =
      let
        mkSubnetIP =
          { prefix, prefixLength }:
          interface: suffix: {
            address = prefix + suffix;
            inherit prefixLength interface;
          };
        mkServerIP = mkSubnetIP {
          prefix = "172.16.15.";
          prefixLength = 24;
        };
        mkWyseIP = mkServerIP "enp1s0";
      in
      {
        wyse-DX = mkWyseIP "50";
        wyse-CW = mkWyseIP "51";
        wyse-91 = mkWyseIP "52";
        wyse-F8 = mkWyseIP "53";
        wyse-F4 = mkWyseIP "54";
        tinyca = mkServerIP "enu1u1u1" "20";
      };
  };
}
