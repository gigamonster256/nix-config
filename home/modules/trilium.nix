{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkPackageOption;
  cfg = config.programs.trilium;
in
{
  options = {
    programs.trilium = {
      enable = mkEnableOption "Trilium";
      package = mkPackageOption pkgs "trilium-next-desktop" { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    impermanence.directories = [
      ".local/share/trilium-data"
    ];
  };
}
