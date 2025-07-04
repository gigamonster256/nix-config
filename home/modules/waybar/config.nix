{ lib, config, ... }:
let
  inherit (lib)
    mkIf
    getExe
    ;
  icon = symbol: "<span font_desc='Font Awesome 6 Free'>${symbol}</span>";
  textIcon = text: i: "${text} ${icon i}";
in
{
  layer = "top";
  position = "top";
  height = 24;
  modules-left = [
    "hyprland/workspaces"
  ];
  modules-center = [
    "hyprland/window"
  ];
  modules-right = [
    "wireplumber"
    "network"
    "cpu"
    "battery"
    "power-profiles-daemon"
    "tray"
    "clock"
  ];
  "hyprland/workspaces" = {
    all-outputs = false;
    disable-scroll = true;
    format = icon "{icon}";
    format-icons = {
      default = "";
      active = "";
      urgent = "";
    };
  };
  wireplumber = {
    reverse-scrolling = 1;
    format = textIcon "{volume}%" "{icon}";
    format-muted = textIcon "MUTE" "";
    format-icons = [
      ""
      ""
    ];
    on-click =
      let
        sonuscfg = config.programs.sonusmix;
      in
      mkIf sonuscfg.enable "${getExe sonuscfg.package}";
  };
  network = {
    format-disconnected = textIcon "Disconnected" "⚠";
    format-ethernet = textIcon "{ipaddr}" "";
    format-wifi = textIcon "{essid}" "";
  };
  cpu = {
    format = textIcon "{usage}%" "";
  };
  memory = {
    format = textIcon "{}%" "";
  };
  power-profiles-daemon = {
    format = icon "{icon}";
    format-icons = {
      default = "";
      performance = "";
      balanced = "";
      power-saver = "";
    };
  };
  battery = {
    format = textIcon "{capacity}%" "{icon}";
    format-icons = [
      ""
      ""
      ""
      ""
      ""
    ];
    states = {
      critical = 15;
      warning = 30;
    };
  };
  tray = {
    spacing = 10;
  };
  clock = {
    format = "{:%I:%M}"; # 12 hour time
    tooltip-format = "{:%Y-%m-%d}";
  };
}
