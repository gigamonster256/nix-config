{ pkgs, ... }:
{
  impermanence.enable = true;

  home.packages = builtins.attrValues {
    inherit (pkgs)
      wpa_supplicant_gui
      ntop
      vscode-fhs
      ;
  };

  programs.spicetify.enable = true;
  programs.ghostty.enable = true;
  programs.firefox.enable = true;
  programs.slack.enable = true;
  programs.trilium.enable = true;
  wayland.windowManager.hyprland.enable = true;
}
