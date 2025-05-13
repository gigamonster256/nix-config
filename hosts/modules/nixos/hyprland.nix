{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    ;
  cfg = config.programs.hyprland;
in
{
  programs.hyprland.withUWSM = mkDefault true;
  environment.sessionVariables.NIXOS_OZONE_WL = mkIf cfg.enable 1;
}
