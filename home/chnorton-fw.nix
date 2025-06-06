{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      wpa_supplicant_gui
      ntop
      ;
  };

  programs.spicetify.enable = true;
  programs.ghostty.enable = true;
  programs.firefox.enable = true;
  programs.slack.enable = true;
  programs.trilium.enable = true;
  programs.vscode.enable = true;
  programs.vesktop.enable = true;
  programs.bitwarden.enable = true;

  # folder for persistent projects
  impermanence.directories = [ "git" ];

  wayland.windowManager.hyprland.enable = true;
}
