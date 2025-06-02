{ pkgs, config, ... }:
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";
    targets.firefox.profileNames = [ "default" ];
    opacity = {
      desktop = 0.0;
      terminal = 0.85;
    };
    cursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
    iconTheme =
      let
        name = "Papirus";
      in
      {
        enable = pkgs.stdenv.isLinux;
        light = name;
        dark = name;
        package = pkgs.papirus-icon-theme;
      };
  };
  # TODO: upstream this to stylix?
  home.pointerCursor = {
    enable = config.wayland.windowManager.hyprland.enable;
    hyprcursor.enable = config.wayland.windowManager.hyprland.enable;
  };
}
