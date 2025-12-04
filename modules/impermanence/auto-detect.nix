{
  persistence.programs = {
    nixos = {
      bluetooth = {
        namespace = "hardware";
        directories = [ "/var/lib/bluetooth" ];
      };
      fprintd = {
        namespace = "services";
        directories = [ "/var/lib/fprint" ];
      };
    };

    nixos-home = {
      zoom-us = {
        directories = [ ".zoom" ];
        files = [
          ".config/zoom.conf"
          ".config/zoomus.conf"
        ];
      };
      alvr = {
        directories = [
          ".config/alvr"
          ".config/openvr"
        ];
      };
      gnome-keyring = {
        namespace = [
          "services"
          "gnome"
        ];
        directories = [ ".local/share/keyrings" ];
      };
    };
  };
}
