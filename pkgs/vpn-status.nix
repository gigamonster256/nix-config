let
  vpn-status =
    {
      lib,
      writeShellApplication,
      iproute2,

      interfaces ? [
        "tun0"
        "wg0"
      ],
    }:
    writeShellApplication {
      name = "vpn-status";

      runtimeInputs = [ iproute2 ];

      text = ''
        VPN_INTERFACES=(${lib.escapeShellArgs interfaces})
        active_interface=""
        for interface in "''${VPN_INTERFACES[@]}"; do
            if ip link show "$interface" > /dev/null 2>&1; then
                active_interface=$interface
                break
            fi
        done
        if [ -n "$active_interface" ]; then
            echo "{\"text\": \"VPN: $active_interface\", \"class\": \"active\"}"
        else
            echo "{\"text\": \"\", \"class\": \"inactive\"}"
        fi
      '';
    };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.waybar-vpn-status = pkgs.callPackage vpn-status { };
    };
}
