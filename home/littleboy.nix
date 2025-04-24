{pkgs, ...}: {
  home.packages = [
    pkgs.unstable.trilium-next-desktop
    pkgs.wpa_supplicant_gui
  ];

  programs.spicetify.enable = true;
  programs.waybar.enable = true;
  programs.ghostty.enable = true;
  programs.firefox.enable = true;
  wayland.windowManager.hyprland.enable = true;
}
