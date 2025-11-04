{ moduleWithSystem, ... }:
{
  unify.hosts.nixos.chnorton-fw.nixos = {
    home-manager.users.caleb = moduleWithSystem (
      { self', ... }:
      { pkgs, ... }:
      {
        home.packages = builtins.attrValues {
          inherit (pkgs)
            wpa_supplicant_gui
            chirp
            ;
          inherit (pkgs.kdePackages)
            okular
            ;
          inherit (pkgs.python3Packages)
            meshtastic
            ;
          inherit (self'.packages)
            ntop
            ;
        };

        # amd gpu
        programs.btop.package = pkgs.btop-rocm;

        programs.spotify.enable = true;
        programs.ghostty.enable = true;
        programs.firefox.enable = true;
        programs.trilium.enable = true;
        programs.vesktop.enable = true;
        programs.bitwarden.enable = true;
        programs.cemu.enable = true;
        programs.ryujinx.enable = true;
        programs.wiiu-downloader.enable = true;
        programs.element.enable = true;
        programs.newsflash.enable = true;
        programs.onlyoffice.enable = true;
        programs.prismlauncher.enable = true;

        # battery is set to charge to 80% max
        # sudo framework_tool --charge-limit
        programs.waybar.settings.mainBar.battery.full-at = 80;

        # disable main screen when lid closed
        wayland.windowManager.hyprland.settings = {
          bindl = [
            ",switch:on:Lid Switch,exec,hyprctl keyword monitor 'desc:BOE,disabled'"
            ",switch:off:Lid Switch,exec,hyprctl keyword monitor 'desc:BOE,preferred,auto,1.566667'"
          ];
        };
      }
    );
  };
}
