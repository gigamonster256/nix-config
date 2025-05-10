{
  pkgs,
  lib,
  config,
  ...
}:
lib.mkMerge [
  {
    programs.waybar = {
      settings.mainBar = lib.mkDefault (import ./config.nix);
      style = lib.mkDefault (builtins.readFile ./style.css);
    };
  }
  (lib.mkIf
    config.programs.waybar.enable
    {
      fonts.fontconfig.enable = lib.mkDefault true;
      home.packages = [
        pkgs.font-awesome
      ];
    })
]
