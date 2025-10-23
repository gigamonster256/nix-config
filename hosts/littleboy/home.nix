{
  configurations.nixos.littleboy = {
    home-manager.users.caleb =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.wpa_supplicant_gui
          # pkgs.ntop
        ];

        programs.spotify.enable = true;
        programs.ghostty.enable = true;
        programs.firefox.enable = true;
        wayland.windowManager.hyprland.enable = true;
      };
  };
}
