{ moduleWithSystem, ... }:
{
  unify.modules.vpn.nixos = moduleWithSystem (
    { self', ... }:
    {
      lib,
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
        TAMU = {
          protocol = "anyconnect";
          gateway = "connect.tamu.edu";
          user = "chnorton";
          passwordFile = config.sops.secrets."vpn/tamu".path;
          autoStart = false;
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

      environment.defaultPackages = [
        (self'.packages.vpn-scripts.override {
          services = allServiceNames;
        })
      ];
    }
  );
}
