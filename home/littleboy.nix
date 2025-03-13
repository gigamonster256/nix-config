{pkgs, ...}: {
  home.packages = [
    pkgs.trilium-desktop
    pkgs.wpa_supplicant_gui
  ];

  programs.spicetify.enable = true;
  programs.waybar.enable = true;
  programs.ghostty.enable = true;
  programs.firefox.enable = true;

  # TODO: refactor this
  programs.btop.enable = true;
  home.file."./.config/btop/themes" = {
    source = "${pkgs.btop-themes.catppuccin}/share/btop/themes";
  };
}
