{
  flake.modules =
    let
      # dont have access to pkgs at flake scope :(
      wallpaper =
        p:
        p.fetchurl {
          url = "https://raw.githubusercontent.com/it-is-zane/wallpapers/main/NixOS/NixOS_Smoke.png";
          hash = "sha256-Jq+8Dwc2x8EI+hpuYa6MQqEcynOJjXgxksLetmTd3w0=";
        };
    in
    {
      homeManager.desktop =
        {
          lib,
          config,
          pkgs,
          ...
        }:
        {
          services.hyprpaper = {
            enable = lib.mkDefault (
              config.wayland.windowManager.hyprland.enable && !config.programs.noctalia-shell.enable
            );
            settings = {
              wallpaper = [
                {
                  monitor = "*";
                  path = "${wallpaper pkgs}";
                  # mode = "cover";
                }
              ];
            };
          };

        };

      homeManager.noctalia =
        { pkgs, ... }:
        {
          xdg.cacheFile."noctalia/wallpapers.json" = {
            text = builtins.toJSON {
              defaultWallpaper = wallpaper pkgs;
              # wallpapers = {
              # "DP-1" = "/path/to/monitor/wallpaper.png";
              # };
            };
          };
        };
    };
}
