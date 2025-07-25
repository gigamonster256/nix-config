{
  lib,
  config,
  ...
}:
{
  sops.secrets = lib.genAttrs [ "vpn/tamu" "vpn/windscribe/private" "vpn/windscribe/preshared" ] (_: {
    sopsFile = ../secrets.yaml;
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

  security.polkit.extraConfig = # javascript
    ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.isInGroup("vpn")) {
          var unit = action.lookup("unit");
          if (unit == "openconnect-TAMU.service") {
            return polkit.Result.YES;
          }
        }
      });
    '';

  users.groups.vpn = { };
}
