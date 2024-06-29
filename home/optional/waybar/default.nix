{
  programs.waybar = {
    enable = true;
    settings.mainBar = import ./waybar.nix;
  };
}
