{
  unify.modules.desktop.home =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      wallpaper = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/it-is-zane/wallpapers/main/NixOS/NixOS_Smoke.png";
        hash = "sha256-Jq+8Dwc2x8EI+hpuYa6MQqEcynOJjXgxksLetmTd3w0=";
      };
    in
    {
      services.hyprpaper = {
        enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
        settings = {
          preload = [ "${wallpaper}" ];
          # TODO: abstract monitors
          wallpaper = [ "eDP-1,${wallpaper}" ];
        };
      };
    };
}
