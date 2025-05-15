{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  home.pointerCursor = {
    enable = mkDefault config.wayland.windowManager.hyprland.enable;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };
}
