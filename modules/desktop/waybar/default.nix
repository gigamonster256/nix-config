{
  flake.modules.homeManager.desktop =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.programs.waybar;
    in
    lib.mkMerge [
      {
        programs.waybar = {
          enable = config.wayland.windowManager.hyprland.enable && !config.programs.noctalia-shell.enable;
          # after stylix color definitions
          style = lib.mkAfter (builtins.readFile ./style.css);
          systemd = {
            enable = true;
            # enableInspect = true;
          };
        };
        stylix.targets.waybar = {
          # only color definitions
          addCss = false;
          font = "sansSerif";
        };
      }
      (lib.mkIf cfg.enable {
        fonts.fontconfig.enable = true;
        home.packages = [
          pkgs.font-awesome
        ];
      })
    ];
}
