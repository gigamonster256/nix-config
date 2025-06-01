{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkPackageOption;
  cfg = config.programs.slack;
in
{
  options = {
    programs.slack = {
      enable = mkEnableOption "Slack";
      package = mkPackageOption pkgs "slack" { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    impermanence.directories = [
      ".config/Slack"
    ];
  };
}
