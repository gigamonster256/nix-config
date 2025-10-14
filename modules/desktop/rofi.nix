{
  unify.modules.desktop.home =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib) mkDefault getExe;
    in
    {
      programs.rofi = {
        enable = mkDefault config.wayland.windowManager.hyprland.enable;
        # package = mkDefault pkgs.rofi-wayland; # wayland support has been upstreamed
        plugins = mkDefault [ pkgs.rofi-emoji ];
        terminal = mkDefault "${getExe config.programs.ghostty.package}";
      };
    };
}
