{ lib, config, ... }:
let
  inherit (lib) mkIf;
in
mkIf config.wayland.windowManager.hyprland.enable {
  services.fnott = {
    enable = true;
    settings = {
      main = {
        default-timeout = 10;
        idle-timeout = 5;
      };
    };
  };
}
