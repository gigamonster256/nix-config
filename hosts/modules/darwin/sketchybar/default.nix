{
  config,
  pkgs,
  lib,
  ...
}: {
  services.sketchybar = {
    config = lib.mkDefault (import ./config.nix {
      inherit config pkgs;
    });
  };
  fonts.packages = lib.mkIf config.services.sketchybar.enable [
    pkgs.sketchybar-app-font
  ];
}
