{
  nixpkgs.overlays = [
    (final: prev: {
      hyprpaper = prev.hyprpaper.overrideAttrs (oldAttrs: {
        patches = oldAttrs.patches or [ ] ++ [
          # wildcard monitor matching
          (final.fetchpatch2 {
            url = "https://patch-diff.githubusercontent.com/raw/hyprwm/hyprpaper/pull/315.patch?full_index=1";
            hash = "sha256-RSwO6VUIFAVwAwY1DaIle72PP6xvmNM4TXpVmMF01ag=";
          })
        ];
      });
    })
  ];

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
          wallpaper = [
            {
              monitor = "*";
              path = wallpaper.outPath;
              # mode = "cover";
            }
          ];
        };
      };
    };
}
