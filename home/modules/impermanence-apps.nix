{ myLib, config, ... }:
let
  inherit (myLib) mkPersistentProgram;
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
  ];
}
