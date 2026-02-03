{
  unify.modules.niri.nixos = {
    programs.niri.enable = true;
    # services.displayManager.defaultSession = "niri";
    # disable autologin to choose niri vs hyprland
    services.displayManager.autoLogin.enable = false;
  };

  # set by config.nix
  # persistence.programs.nixos-home = {
  #   niri = {
  #     directories = [ ".config/niri" ];
  #   };
  # };
}
