{
  flake.modules.nixos.base =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib)
        mkDefault
        mkIf
        ;
      cfg = config.programs.hyprland;
    in
    {
      programs.hyprland.withUWSM = mkDefault true;
      environment.sessionVariables.NIXOS_OZONE_WL = mkIf cfg.enable 1;
    };
  flake.modules.homeManager.base =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib) mkIf;
    in
    {

      # gtk portal and nautilus as file picker
      config = mkIf config.wayland.windowManager.hyprland.enable {
        home.packages = builtins.attrValues {
          inherit (pkgs)
            nautilus
            wl-clipboard
            ;
        };
        xdg.portal = {
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          xdgOpenUsePortal = true;
          config.gtk."org.freedesktop.impl.portal.FileChooser" = "nautilus";
        };
      };
    };
}
