{
  flake.modules.homeManager.desktop =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      programs.rofi = {
        enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
        plugins = lib.mkDefault [ pkgs.rofi-emoji ];
        settings.terminal = lib.mkDefault "${config.programs.ghostty.openCommand} --keybind=clear --confirm-close-surface=false";
      };
    };

  persistence.programs.homeManager = {
    rofi = {
      files = [ ".cache/rofi3.druncache" ];
    };
  };
}
