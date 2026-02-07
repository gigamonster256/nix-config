{
  persistence.programs.homeManager = {
    syncthing = {
      namespace = "services";
      directories = [ ".local/state/syncthing" ];
    };

    syncthing-tray = {
      name = "tray";
      namespace = [
        "services"
        "syncthing"
      ];
      files = [ ".config/syncthingtray.ini" ];
    };
  };
}
