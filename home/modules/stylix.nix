{ pkgs, config, ... }:
{
  stylix = {
    # FIXME: auto set this for home-manager standalone and nix-darwin
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";
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
    targets.firefox.profileNames = [ "default" ];
  };

  # TODO: upstream this to stylix?
  home.pointerCursor = rec {
    inherit (config.wayland.windowManager.hyprland) enable;
    hyprcursor.enable = enable;
  };
}
