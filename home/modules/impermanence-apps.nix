{ config, ... }:
let
  mkPersistentProgram =
    {
      name,
      defaultEnable ? false,
      packageName ? name,
      packageOptions ? { },
      directories ? [ ],
      files ? [ ],
    }:
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib) mkIf mkEnableOption mkPackageOption;
      cfg = config.programs.${name};
    in
    {
      options = {
        programs.${name} = {
          enable = mkEnableOption name // {
            default = defaultEnable;
          };
          package = mkPackageOption pkgs packageName packageOptions;
        };
      };

      config = mkIf cfg.enable {
        home.packages = [ cfg.package ];
        impermanence = {
          inherit directories files;
        };
      };
    };
in
{
  imports = [
    (mkPersistentProgram {
      name = "trilium";
      packageName = "trilium-next-desktop";
      directories = [ ".local/share/trilium-data" ];
    })
    (mkPersistentProgram {
      name = "slack";
      directories = [ ".config/Slack" ];
    })
    (mkPersistentProgram {
      name = "sonusmix";
      directories = [ ".local/share/org.sonusmix.Sonusmix" ];
      defaultEnable = config.wayland.windowManager.hyprland.enable;
    })
    (mkPersistentProgram {
      name = "bitwarden";
      packageName = "bitwarden-desktop";
      directories = [ ".config/Bitwarden" ];
    })
    (mkPersistentProgram {
      name = "cemu";
      directories = [
        ".config/Cemu"
        ".local/share/Cemu"
        ".cache/Cemu"
      ];
    })
    (mkPersistentProgram {
      name = "ryujinx";
      packageName = "ryubing";
      directories = [ ".config/Ryujinx" ];
    })
    (mkPersistentProgram {
      name = "wiiu-downloader";
      directories = [ ".config/WiiUDownloader" ];
    })
    (mkPersistentProgram {
      name = "element";
      packageName = "element-desktop";
      directories = [ ".config/Element" ];
    })
    (mkPersistentProgram {
      name = "newsflash";
      directories = [
        ".config/news-flash"
        ".local/news-flash"
        ".local/news_flash" # waiting on https://gitlab.com/news-flash/news_flash_gtk/-/commit/408fc0f17621e0123cb597833bf2d1053e79ac01 to land (v4.0.0)
      ];
    })
  ];
}
