{ pkgs, ... }:
{
  impermanence.enable = true;

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
  wayland.windowManager.hyprland.enable = true;

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    targets.firefox.profileNames = [ "default" ];
  };
}
