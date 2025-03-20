{
  lib,
  config,
  ...
}: {
  programs.hyprland = {
    withUWSM = lib.mkDefault true;
  };
  environment.sessionVariables.NIXOS_OZONE_WL = lib.mkIf config.programs.hyprland.enable 1;
}
