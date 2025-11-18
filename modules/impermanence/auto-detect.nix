{
  unify.modules.impermanence = {
    nixos =
      { lib, config, ... }:
      {
        home-manager.sharedModules = [
          # these programs store data in the home directory
          # but are configured at the system level
          (lib.mkIf config.programs.zoom-us.enable {
            impermanence = {
              directories = [ ".zoom" ];
              files = [
                ".config/zoom.conf"
                ".config/zoomus.conf"
              ];
            };
          })
          (lib.mkIf config.programs.alvr.enable {
            impermanence.directories = [
              ".config/alvr"
              ".config/openvr"
            ];
          })
          (lib.mkIf config.services.gnome.gnome-keyring.enable {
            impermanence.directories = [ ".local/share/keyrings" ];
          })
        ];
      };
  };

  impermanence.programs.nixos = {
    bluetooth = {
      namespace = "hardware";
      directories = [ "/var/lib/bluetooth" ];
    };
    fprintd = {
      namespace = "services";
      directories = [ "/var/lib/fprint" ];
    };
  };
}
