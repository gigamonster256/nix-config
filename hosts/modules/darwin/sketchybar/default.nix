{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  cfg = config.services.sketchybar;
in
{
  services.sketchybar.config = mkDefault (
    import ./config.nix {
      inherit lib pkgs config;
    }
  );
  fonts.packages = mkIf cfg.enable [
    pkgs.sketchybar-app-font
    (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
}
