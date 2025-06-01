{ pkgs, ... }:
{
  impermanence.enable = true;

  home.packages = builtins.attrValues {
    inherit (pkgs)
      wpa_supplicant_gui
      ntop
      slack
      trilium-next-desktop
      ;
  };

  impermanence.directories = [
    ".config/Slack"
    ".local/share/trilium-data"
  ];

  programs.spicetify.enable = true;
  programs.ghostty.enable = true;
  programs.firefox.enable = true;
  wayland.windowManager.hyprland.enable = true;

}
