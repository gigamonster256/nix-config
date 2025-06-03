{ pkgs, ... }:
{
  home.packages = [
    pkgs.wpa_supplicant_gui
    pkgs.ntop
  ];

  programs.spicetify.enable = true;
  programs.ghostty.enable = true;
  programs.firefox.enable = true;
  wayland.windowManager.hyprland.enable = true;
}
