{
  flake.modules.darwin.base =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib) mkIf;
      cfg = config.services.sketchybar;
    in
    {
      fonts.packages = mkIf cfg.enable [
        # pkgs.sketchybar-app-font # https://github.com/NixOS/nixpkgs/pull/484046
        pkgs.nerd-fonts.jetbrains-mono
      ];
    };
}
