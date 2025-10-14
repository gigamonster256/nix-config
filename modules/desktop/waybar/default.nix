{
  unify.modules.desktop.home =
    {
      lib,
      pkgs,
      config,
      ...
    }@inputs:
    let
      inherit (lib)
        mkIf
        mkMerge
        mkAfter
        ;
      cfg = config.programs.waybar;
    in
    mkMerge [
      {
        programs.waybar = {
          enable = config.wayland.windowManager.hyprland.enable;
          # after stylix color definitions
          style = mkAfter (builtins.readFile ./style.css);
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
      (mkIf cfg.enable {
        fonts.fontconfig.enable = true;
        home.packages = [
          pkgs.font-awesome
        ];
      })
    ];
}
