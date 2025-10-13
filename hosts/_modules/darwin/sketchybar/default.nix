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
      services.sketchybar.config = mkDefault (
        import ./_config.nix {
          inherit lib pkgs config;
        }
      );
      fonts.packages = mkIf cfg.enable [
        pkgs.sketchybar-app-font
        pkgs.nerd-fonts.jetbrains-mono
      ];
    };
}
