{
  battery = {
    format = "{icon} {capacity}%";
    format-icons = ["" "" "" "" ""];
    states = {
      critical = 15;
      good = 95;
      warning = 30;
    };
  };
  "clock#1" = {
    format = "{:%a}";
    tooltip = false;
  };
  "clock#2" = {
    format = "{:%H:%M}";
    tooltip = false;
  };
  "clock#3" = {
    format = "{:%m-%d}";
    tooltip = false;
  };
  cpu = {
    format = "CPU {usage:2}%";
    interval = 5;
  };
  "custom/left-arrow-dark" = {
    format = "";
    tooltip = false;
  };
  "custom/left-arrow-light" = {
    format = "";
    tooltip = false;
  };
  "custom/right-arrow-dark" = {
    format = "";
    tooltip = false;
  };
  "custom/right-arrow-light" = {
    format = "";
    tooltip = false;
  };
  disk = {
    format = "Disk {percentage_used:2}%";
    interval = 5;
    path = "/";
  };
  layer = "top";
  memory = {
    format = "Mem {}%";
    interval = 5;
  };
  modules-center = ["custom/left-arrow-dark" "clock#1" "custom/left-arrow-light" "custom/left-arrow-dark" "clock#2" "custom/right-arrow-dark" "custom/right-arrow-light" "clock#3" "custom/right-arrow-dark"];
  modules-left = ["sway/workspaces" "custom/right-arrow-dark"];
  modules-right = ["custom/left-arrow-dark" "pulseaudio" "custom/left-arrow-light" "custom/left-arrow-dark" "memory" "custom/left-arrow-light" "custom/left-arrow-dark" "cpu" "custom/left-arrow-light" "custom/left-arrow-dark" "battery" "custom/left-arrow-light" "custom/left-arrow-dark" "disk" "custom/left-arrow-light" "custom/left-arrow-dark" "tray"];
  position = "top";
  pulseaudio = {
    format = "{icon} {volume:2}%";
    format-bluetooth = "{icon}  {volume}%";
    format-icons = {
      default = ["" ""];
      headphones = "";
    };
    format-muted = "MUTE";
    on-click = "pamixer -t";
    on-click-right = "pavucontrol";
    scroll-step = 5;
  };
  "sway/workspaces" = {
    disable-scroll = true;
    format = "{name}";
  };
  tray = {icon-size = 20;};
}
