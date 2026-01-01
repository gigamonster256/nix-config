{
  unify.modules.desktop.nixos =
    { lib, config, ... }:
    let
      cfg = config.programs.hyprland;
    in
    {
      # hyprland
      programs.hyprland.enable = true;
      programs.hyprlock.enable = true;
      # programs.hyprland.withUWSM = lib.mkDefault true;
      environment.sessionVariables.NIXOS_OZONE_WL = lib.mkIf cfg.enable 1;
    };

  unify.modules.desktop.home =
    { pkgs, ... }:
    {
      # gtk portal and nautilus as file picker
      wayland.windowManager.hyprland.enable = true;
      home.packages = builtins.attrValues {
        inherit (pkgs)
          nautilus
          wl-clipboard
          ;
      };
      xdg.portal = {
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        xdgOpenUsePortal = true;
        config.gtk."org.freedesktop.impl.portal.FileChooser" = "nautilus";
      };
      # auto start on tty1
      programs.zsh.profileExtra = ''
        if [ "$(tty)" = "/dev/tty1" ] && [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          exec start-hyprland
        fi
      '';
    };
}
