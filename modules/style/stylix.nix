{ inputs, lib, ... }:
{
  unify.modules.style.nixos =
    { pkgs, ... }:
    {
      imports = [
        inputs.stylix.nixosModules.stylix
      ];

      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        polarity = "dark";
        opacity = {
          desktop = 0.0;
          terminal = 0.85;
        };
        cursor = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 24;
        };
      };
    };

  flake.modules.darwin.style =
    { pkgs, ... }:
    {
      imports = [
        inputs.stylix.darwinModules.stylix
      ];

      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        polarity = "dark";
        opacity = {
          desktop = 0.0;
          terminal = 0.85;
        };
        # cursor = {
        #   name = "Bibata-Modern-Classic";
        #   package = pkgs.bibata-cursors;
        #   size = 24;
        # };
      };
    };

  unify.modules.style.home =
    {
      pkgs,
      config,
      ...
    }:
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
        # name = "Bibata-Modern-Classic";
        # package = pkgs.bibata-cursors;
        inherit (config.wayland.windowManager.hyprland) enable;
        hyprcursor.enable = enable;
      };
    };
}
