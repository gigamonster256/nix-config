{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      wpa_supplicant_gui
      ntop
      ;
    inherit (pkgs.kdePackages)
      okular
      ;
  };

  # amd gpu
  programs.btop.package = pkgs.btop-rocm;

  programs.spicetify.enable = true;
  programs.ghostty.enable = true;
  programs.firefox.enable = true;
  programs.slack.enable = true;
  programs.trilium.enable = true;
  programs.vscode.enable = true;
  programs.vesktop.enable = true;
  programs.bitwarden.enable = true;
  programs.cemu.enable = true;
  programs.ryujinx.enable = true;
  programs.wiiu-downloader.enable = true;
  programs.element.enable = true;
  programs.newsflash.enable = true;
  programs.gemini-cli.enable = true;

  # folder for persistent projects
  impermanence.directories = [ "git" ];

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

  wayland.windowManager.hyprland.enable = true;
}
