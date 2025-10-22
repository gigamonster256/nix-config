{
  flake.modules.darwin.base =
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
      fonts.packages = mkIf cfg.enable [
        pkgs.sketchybar-app-font
        pkgs.nerd-fonts.jetbrains-mono
      ];
    };
}
