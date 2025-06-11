{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  imports = [
    ./hyprland.nix
    ./hyprlock.nix
    ./hypridle.nix
  ];

  # gtk portal and nautilus as file picker
  config = mkIf config.wayland.windowManager.hyprland.enable {
    home.packages = builtins.attrValues {
      inherit (pkgs)
        nautilus
        wl-clipboard
        ;
    };
    xdg.portal = {
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      xdgOpenUsePortal = true;
      config.gtk."org.freedesktop.impl.portal.FileChooser" = "nautilus";
    };
  };
}
