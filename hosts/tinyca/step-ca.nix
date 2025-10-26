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
          kms.uri = "yubikey:pin-source=${config.sops.secrets."yubikey/pin".path}";
          key = "yubikey:slot-id=9c";
        };
      };
  };
}
