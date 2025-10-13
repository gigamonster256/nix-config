{
  flake.modules.nixos.step-ca =
    {
      lib,
      config,
      ...
    }:
    {
      sops.secrets."yubikey/pin" =
        let
          inherit (config.systemd.services) step-ca;
        in
        {
          owner = step-ca.serviceConfig.User;
          sopsFile = ./secrets.yaml;
          restartUnits = [ step-ca.name ];
        };
      services.step-ca = {
        enable = true;
        address = ""; # all interfaces
        port = 443;
        openFirewall = true;
        settings =
          (lib.pipe ./config/ca.json [
            builtins.readFile
            builtins.fromJSON
          ])
          // {
            root = ./certs/root_ca.crt;
            crt = ./certs/intermediate_ca.crt;
            kms.uri = "yubikey:pin-source=${config.sops.secrets."yubikey/pin".path}";
            db = {
              type = "badgerv2";
              dataSource = "${config.users.users.step-ca.home}/db";
              badgerLoadingFileMode = "";
            };
          };
        # TODO: remove dependence on intermediatePasswordFile upstream...
        # I'm using a yubikey so this is a dummy value to satisfy the nixos module
        intermediatePasswordFile = config.sops.secrets."yubikey/pin".path;
      };
      systemd.services.step-ca.after = with config.systemd.services; [
        pcscd.name
        infnoise.name
      ];
    };
}
