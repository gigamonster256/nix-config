{
  flake.modules.homeManager.desktop =
    {
      lib,
      config,
      ...
    }:
    # FIXME: decouple from hyprland
    lib.mkIf config.wayland.windowManager.hyprland.enable {
      services.fnott = {
        enable = lib.mkDefault (!config.programs.noctalia-shell.enable);
        settings = {
          main = {
            default-timeout = 10;
            idle-timeout = 5;
          };
        };
      };
    };
}
