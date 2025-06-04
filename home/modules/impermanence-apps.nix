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
      packageName = "slack";
      directories = [ ".config/Slack" ];
    })
    (mkPersistentProgram {
      name = "sonusmix";
      packageName = "sonusmix";
      directories = [ ".local/share/org.sonusmix.Sonusmix" ];
      defaultEnable = config.wayland.windowManager.hyprland.enable;
    })
  ];
}
