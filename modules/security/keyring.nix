{
  flake.modules.nixos.desktop = {
    services.gnome.gnome-keyring.enable = true;
    # programs.seahorse.enable = true;
    # FIXME: dont hardcode name - also doesnt work with autologin or fingerprint (i think)
    # security.pam.services.caleb.enableGnomeKeyring = true;
  };

  persistence.programs.nixos-home = {
    gnome-keyring = {
      namespace = [
        "services"
        "gnome"
      ];
      directories = [ ".local/share/keyrings" ];
    };
  };
}
