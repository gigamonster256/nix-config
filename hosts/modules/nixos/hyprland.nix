{
  lib,
  config,
  ...
}: {
  programs.hyprland = {
    withUWSM = lib.mkDefault true;
  };
  environment.sessionVariables = lib.mkIf config.programs.hyprland.enable {NIXOS_OZONE_WL = "1";};
}
