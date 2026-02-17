{
  flake.modules.darwin.base =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.services.sketchybar;
    in
    {
      fonts.packages = lib.mkIf cfg.enable [
        # pkgs.sketchybar-app-font # https://github.com/NixOS/nixpkgs/pull/484046
        pkgs.nerd-fonts.jetbrains-mono
      ];
    };
}
