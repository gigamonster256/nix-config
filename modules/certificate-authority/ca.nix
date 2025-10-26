{
  flake.modules.nixos.step-ca =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      services.step-ca = {
        enable = true;
        address = ""; # all interfaces
        port = 443;
        openFirewall = true;
        settings =
          (lib.pipe ./ca.json [
            builtins.readFile
            builtins.fromJSON
          ])
          // {
            root = ./certs/root_ca.crt;
            crt = ./certs/intermediate_ca.crt;
            db = {
              type = "badgerv2";
              dataSource = "${config.users.users.step-ca.home}/db";
              badgerLoadingFileMode = "";
            };
          };
      };

      environment.systemPackages = with pkgs; [
        # step-cli
        # yubikey-manager
      ];

      services.pcscd.enable = true;
      services.infnoise.enable = true;

      # start pcscd and infnoise before step-ca
      systemd.services.step-ca.after = with config.systemd.services; [
        pcscd.name
        infnoise.name
      ];

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
    };
}
