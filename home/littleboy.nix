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

  impermanence.enable = true;

  stylix = {
    enable = true;
    # autoEnable = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    targets.rofi.enable = true;
    targets.firefox.profileNames = [ "default" ];
  };
}
