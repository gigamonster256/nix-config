{ lib, config, ... }:
let
  inherit (lib) mkIf getExe;
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
    "memory"
    "battery"
    "tray"
    "clock"
  ];
  "hyprland/workspaces" = {
    all-outputs = false;
    disable-scroll = true;
    format = "{icon}";
    format-icons = {
      default = "";
      active = "";
      urgent = "";
    };
  };
  wireplumber = {
    reverse-scrolling = 1;
    format = "{volume}% {icon}";
    format-bluetooth = "{volume}% {icon}";
    format-icons = {
      car = "";
      default = [
        ""
        ""
      ];
      handsfree = "";
      headphones = "";
      headset = "";
      phone = "";
      portable = "";
    };
    format-muted = "MUTE ";
    on-click =
      let
        sonuscfg = config.programs.sonusmix;
      in
      mkIf sonuscfg.enable "${getExe sonuscfg.package}";
  };
  network = {
    format-disconnected = "Disconnected ⚠";
    format-ethernet = "{ipaddr} ";
    format-wifi = "{essid} ";
  };
  cpu = {
    format = "{usage}% ";
  };
  memory = {
    format = "{}% ";
  };
  battery = {
    bat = "BAT0";
    format = "{capacity}% {icon}";
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
    tooltip-format = "{:%Y-%m-%d}";
  };
}
