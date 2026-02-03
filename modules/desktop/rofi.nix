{
  unify.modules.desktop.home =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      programs.rofi = {
        enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
        # package = mkDefault pkgs.rofi-wayland; # wayland support has been upstreamed
        plugins = lib.mkDefault [ pkgs.rofi-emoji ];
        terminal = lib.mkDefault "${lib.getExe config.programs.ghostty.package} --keybind=clear";
      };
    };

  persistence.programs.homeManager = {
    rofi = {
      files = [ ".cache/rofi3.druncache" ];
    };
  };
}
