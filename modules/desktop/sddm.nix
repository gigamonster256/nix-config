{
  unify.modules.desktop.nixos =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      services.displayManager = {
        # defaultSession = "hyprland-uwsm"; # default is first installed desktop (fine if only 1 installed)
        # FIXME: dont hardcode this
        autoLogin = {
          enable =
            config.services.displayManager.sessionData ? sessionNames
            && config.services.displayManager.sessionData.sessionNames != [ ]; # some window manager is enabled
          user = lib.mkDefault "caleb";
        };
        sddm = {
          # enable = true;
          wayland.enable = lib.mkDefault false;
          theme = lib.mkDefault "catppuccin-mocha";
          # issue with missing sddm-greeter-qt6
          package = lib.mkDefault pkgs.kdePackages.sddm;
          autoLogin.relogin = lib.mkDefault config.services.displayManager.autoLogin.enable;
        };
      };
      environment.systemPackages =
        let
          sddmcfg = config.services.displayManager.sddm;
        in
        lib.optional (sddmcfg.enable && lib.hasPrefix "catppuccin" sddmcfg.theme) pkgs.catppuccin-sddm;
    };
}
