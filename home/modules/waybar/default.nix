{
  lib,
  pkgs,
  config,
  ...
}@inputs:
let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkForce
    ;
  cfg = config.programs.waybar;
in
mkMerge [
  {
    programs.waybar = {
      enable = mkDefault config.wayland.windowManager.hyprland.enable;
      settings.mainBar = mkDefault (import ./config.nix inputs);
      style = mkForce (builtins.readFile ./style.css);
    };
  }
  (mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages = [
      pkgs.font-awesome
    ];
  })
]
