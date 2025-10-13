{
  flake.modules.nixos.base = {
    services.gnome.gnome-keyring.enable = true;
    programs.seahorse.enable = true;
    # FIXME: dont hardcode name - also doesnt work with autologin or fingerprint (i think)
    # security.pam.services.caleb.enableGnomeKeyring = true;
  };
}
