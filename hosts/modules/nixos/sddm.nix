{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.catppuccin-sddm
  ];
  services.displayManager = {
    # defaultSession = "hyprland-uwsm"; # default is first installed desktop (fine if only 1 installed)
    # FIXME: font hardcode this
    autoLogin = {
      enable = true;
      user = "caleb";
    };
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "catppuccin-mocha";
      # issue with missing sddm-greeter-qt6
      package = pkgs.kdePackages.sddm;
      autoLogin.relogin = true;
    };
  };
}
