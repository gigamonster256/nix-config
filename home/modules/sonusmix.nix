{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkPackageOption;
  cfg = config.programs.sonusmix;
in
{
  options = {
    programs.sonusmix = {
      enable = mkEnableOption "Sonusmix" // {
        default = config.wayland.windowManager.hyprland.enable;
      };
      package = mkPackageOption pkgs "sonusmix" { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    impermanence.directories = [
      ".local/share/org.sonusmix.Sonusmix"
    ];
  };
}
