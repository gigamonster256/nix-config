{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  programs.rofi = {
    enable = mkDefault config.wayland.windowManager.hyprland.enable;
    package = mkDefault pkgs.rofi-wayland;
    plugins = mkDefault [ pkgs.rofi-emoji-wayland ];
  };
}
