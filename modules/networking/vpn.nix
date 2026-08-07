{
  flake.modules.nixos.vpn =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      # https://github.com/NixOS/nixpkgs/blob/874be15f3c74c7d15cb804e485428fd444f8755f/nixos/modules/services/networking/wg-quick.nix#L370
      wg-quickServices = lib.mapAttrsToList (
        name: _: "wg-quick-${name}"
      ) config.networking.wg-quick.interfaces;
      # https://github.com/NixOS/nixpkgs/blob/2053850561181daa345d5607bc996c945a0ebc06/nixos/modules/services/networking/openconnect.nix#L157
      openconnectServices = lib.mapAttrsToList (
        name: _: "openconnect-${name}"
      ) config.networking.openconnect.interfaces;
      allServiceNames = wg-quickServices ++ openconnectServices;
    in

    {
      sops.secrets = lib.genAttrs [ "vpn/tamu" "vpn/windscribe/private" "vpn/windscribe/preshared" ] (_: {
        sopsFile = ../secrets/secrets.yaml;
      });

      networking.openconnect.interfaces = {
        TAMU =
          let
            ip = "${pkgs.iproute2}/bin/ip";
            # Texas A&M University public IPv4 blocks from AS1970, AS3794, AS22782
            tamuNetworks = [
              "128.194.0.0/16"
              "165.91.0.0/16"
              "165.95.0.0/16"
              "204.56.128.0/17"
              "192.58.110.0/24"
              "192.58.112.0/22"
              "64.71.80.0/20"
              "66.171.223.0/24"
              "68.232.0.0/19"
              "98.159.48.0/20"
              "184.174.192.0/18"
              # typical tamu private subnets
              "10.0.0.0/8"
            ];

            tamuVpnScript = pkgs.writeShellScript "openconnect-tamu-script" ''
              set -e

              TUNDEV="''${TUNDEV:-}"
              case "$reason" in
                pre-init)
                  ;;
                connect)
                  if [ -n "$INTERNAL_IP4_ADDRESS" ] && [ -n "$TUNDEV" ]; then
                    ${ip} addr add "$INTERNAL_IP4_ADDRESS/$INTERNAL_IP4_NETMASKLEN" dev "$TUNDEV" 2>/dev/null || true
                    ${ip} link set dev "$TUNDEV" up
                    [ -n "$INTERNAL_IP4_MTU" ] && ${ip} link set dev "$TUNDEV" mtu "$INTERNAL_IP4_MTU"
              ${lib.concatMapStringsSep "\n" (
                net: "      ${ip} route replace ${net} dev \"$TUNDEV\" 2>/dev/null || true"
              ) tamuNetworks}
                  fi
                  ;;
                disconnect)
                  if [ -n "$TUNDEV" ]; then
              ${lib.concatMapStringsSep "\n" (
                net: "      ${ip} route del ${net} dev \"$TUNDEV\" 2>/dev/null || true"
              ) tamuNetworks}
                    ${ip} link set dev "$TUNDEV" down 2>/dev/null || true
                  fi
                  ;;
              esac
            '';
          in
          {
            protocol = "anyconnect";
            gateway = "connect.tamu.edu";
            user = "chnorton";
            passwordFile = config.sops.secrets."vpn/tamu".path;
            autoStart = false;
            extraOptions = {
              script = "${tamuVpnScript}";
            };
          };
      };

      networking.wg-quick.interfaces = {
        windscribe = {
          privateKeyFile = config.sops.secrets."vpn/windscribe/private".path;
          address = [ "100.109.252.236/32" ];
          dns = [ "10.255.255.1" ];
          peers = [
            {
              publicKey = "7CGKj3gnMrJ73Q3TX/YPtk94ZqX+H3kfBbMwfhze/Hg=";
              endpoint = "82.21.158.2:443";
              allowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              presharedKeyFile = config.sops.secrets."vpn/windscribe/preshared".path;
            }
          ];
          autostart = false;
        };
      };

      security.polkit.extraConfig =
        let
          svcSuffix = ".service";
          allServices = lib.map (s: s + svcSuffix) allServiceNames;
          # var == unit1 || var == unit2 || ...
          equalsAny = var: l: lib.concatMapStringsSep " || " (svc: "${var} == '${svc}'") l;
        in
        # TODO: use js list.includes?
        # javascript
        ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.isInGroup("vpn")) {
              var unit = action.lookup("unit");
              if (${equalsAny "unit" allServices}) {
                return polkit.Result.YES;
              }
            }
          });
        '';

      users.groups.vpn = { };

      systemd.services = lib.mkIf (config.services.automatic-timezoned.enable or false) (
        lib.genAttrs allServiceNames (_name: {
          serviceConfig.ExecStartPre = "-${lib.getExe' config.systemd.package "systemctl"} stop automatic-timezoned-geoclue-agent.service";
          serviceConfig.ExecStopPost = "-${lib.getExe' config.systemd.package "systemctl"} start automatic-timezoned.service";
        })
      );

      environment.defaultPackages = [
        (pkgs.vpn-scripts.override {
          services = allServiceNames;
        })
      ];
    };
}
