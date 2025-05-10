{
  "layer" = "top"; # Waybar at top layer
  "position" = "top"; # Waybar at the bottom of your screen
  "height" = 24; # Waybar height
  # "width"= 1366; # Waybar width
  # Choose the order of the modules
  "modules-left" = [
    "hyprland/workspaces"
  ];
  "modules-center" = [
    "hyprland/window"
  ];
  "modules-right" = [
    "wireplumber"
    "network"
    "cpu"
    "memory"
    "battery"
    "tray"
    "clock"
  ];
  "hyprland/workspaces" = {
    "disable-scroll" = true;
    "all-outputs" = false;
    "format" = "{icon}";
    "format-icons" = {
      "1=web" = "";
      "2=code" = "";
      "3=term" = "";
      "4=work" = "";
      "5=music" = "";
      "6=docs" = "";
      "urgent" = "";
      "focused" = "";
      "default" = "";
    };
  };
  "tray" = {
    # "icon-size"= 21;
    "spacing" = 10;
  };
  "clock" = {
    "format-alt" = "{=%Y-%m-%d}";
  };
  "cpu" = {
    "format" = "{usage}% ";
  };
  "memory" = {
    "format" = "{}% ";
  };
  "battery" = {
    "bat" = "BAT0";
    "states" = {
      # "good"= 95;
      "warning" = 30;
      "critical" = 15;
    };
    "format" = "{capacity}% {icon}";
    # "format-good"= ""; # An empty format will hide the module
    # "format-full"= "";
    "format-icons" = ["" "" "" "" ""];
  };
  "network" = {
    # "interface"= "wlp2s0"; # (Optional) To force the use of this interface
    "format-wifi" = "{essid} ({signalStrength}%) ";
    "format-ethernet" = "{ifname}= {ipaddr}/{cidr} ";
    "format-disconnected" = "Disconnected ⚠";
  };
  "wireplumber" = {
    "reverse-scrolling" = 1;
    "format" = "{volume}% {icon}";
    "format-bluetooth" = "{volume}% {icon}";
    "format-muted" = "";
    "format-icons" = {
      "headphones" = "";
      "handsfree" = "";
      "headset" = "";
      "phone" = "";
      "portable" = "";
      "car" = "";
      "default" = ["" ""];
    };
    # "on-click"= "pavucontrol"
  };
}
