{ inputs, ... }:
{
  unify.hosts.nixos.tinyca = {
    nixos =
      { config, ... }:
      {
        imports = [
          inputs.self.modules.nixos.step-ca
        ];
        sops.secrets."yubikey/pin" =
          let
            inherit (config.systemd.services) step-ca;
          in
          {
            owner = step-ca.serviceConfig.User;
            sopsFile = ./secrets.yaml;
            restartUnits = [ step-ca.name ];
          };

        services.step-ca.settings = {
          dnsNames = [
            "certs.nortonweb.org"
            "certs.penguin"
          ];
          kms.uri = "yubikey:pin-source=${config.sops.secrets."yubikey/pin".path}";
          key = "yubikey:slot-id=9c";
          ssh = {
            hostKey = "yubikey:slot-id=82";
            userKey = "yubikey:slot-id=83";
          };
        };

        # install pcscd for yubikey support
        services.pcscd.enable = true;

        # allow step-ca user to access pcscd
        users.groups.pcsc = { };
        users.users.step-ca.extraGroups = [ "pcsc" ];
        security.polkit.extraConfig =
          # javascript
          ''
            polkit.addRule(function(action, subject) {
                if (action.id == "org.debian.pcsc-lite.access_card" &&
                    subject.isInGroup("pcsc")) {
                    return polkit.Result.YES;
                }
            });
            polkit.addRule(function(action, subject) {
                if (action.id == "org.debian.pcsc-lite.access_pcsc" &&
                    subject.isInGroup("pcsc")) {
                    return polkit.Result.YES;
                }
            });
          '';

        # infnoise trng for better entropy when generating keys
        services.infnoise.enable = true;

        # start pcscd and infnoise before step-ca
        systemd.services.step-ca.after = with config.systemd.services; [
          pcscd.name
          infnoise.name
        ];
      };
  };
}
