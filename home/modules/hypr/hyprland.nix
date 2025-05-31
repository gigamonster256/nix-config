{
  lib,
  pkgs,
  config,
  ...
}:
{
  wayland.windowManager.hyprland = {
    settings = {
      "$terminal" = "ghostty";
      "$mainMod" = "SUPER";
      ecosystem = {
        no_update_news = true;
      };
      monitor = ",preferred,auto,auto";
      exec-once = [
        "waybar"
      ];
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
      ];
      general = {
        gaps_in = 2;
        gaps_out = 5;
        border_size = 2;
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };
      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];
        animation = [
          "global,1,10,default"
          "border,1,5.39,easeOutQuint"
          "windows,1,4.79,easeOutQuint"
          "windowsIn,1,4.1,easeOutQuint,popin 87%"
          "windowsOut,1,1.49,linear,popin 87%"
          "fadeIn,1,1.73,almostLinear"
          "fadeOut,1,1.46,almostLinear"
          "fade,1,3.03,quick"
          "layers,1,3.81,easeOutQuint"
          "layersIn,1,4,easeOutQuint,fade"
          "layersOut,1,1.5,linear,fade"
          "fadeLayersIn,1,1.79,almostLinear"
          "fadeLayersOut,1,1.39,almostLinear"
          "workspaces,1,1.94,almostLinear,fade"
          "workspacesIn,1,1.21,almostLinear,fade"
          "workspacesOut,1,1.94,almostLinear,fade"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master.new_status = "master";

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = false;
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };
      # https://wiki.hyprland.org/Configuring/Variables/#gestures
      gestures.workspace_swipe = false;
      # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
      bind =
        [
          "$mainMod,Return,exec,$terminal"
          "$mainMod,C,killactive"
          "$mainMod,F,exec,firefox"
          "$mainMod,M,exit,"
          # "$mainMod,E,exec,$fileManager"
          "$mainMod,V,togglefloating,"
          "$mainMod,P,pseudo,"
          "$mainMod,J,togglesplit,"
          # move focus with mainMod + arrow keys
          "$mainMod,left,movefocus,l"
          "$mainMod,right,movefocus,r"
          "$mainMod,up,movefocus,u"
          "$mainMod,down,movefocus,d"
          # scratchpad workspace
          "$mainMod,S,togglespecialworkspace,magic"
          "$mainMod SHIFT,S,movetoworkspace,special:magic"
          # Scroll through existing workspaces with mainMod + scroll
          "$mainMod,mouse_down,workspace,e+1"
          "$mainMod,mouse_up,workspace,e-1"
        ]
        ++ (
          # Switch workspaces with mainMod + [1-9]
          # $mainMod,1,workspace,1
          # Move active window to a workspace with mainMod + SHIFT + [1-9]
          # $mainMod SHIFT,1,movetoworkspace,1
          let
            workspaces = lib.lists.map toString (lib.lists.range 1 9);
            switchModifier = "$mainMod";
            moveModifier = "$mainMod SHIFT";
            switchBindings = lib.lists.map (ws: "${switchModifier},${ws},workspace,${ws}") workspaces;
            moveBindings = lib.lists.map (ws: "${moveModifier},${ws},movetoworkspace,${ws}") workspaces;
          in
          switchBindings ++ moveBindings
        )
        ++ (lib.optional config.programs.hyprlock.enable "$mainMod,L,exec,hyprlock")
        ++ (
          let
            roficfg = config.programs.rofi;
          in
          lib.optional roficfg.enable "$mainMod,Space,exec,${lib.getExe roficfg.finalPackage} -show drun"
        )
        ++ (
          let
            spotifycfg = config.programs.spicetify;
          in
          lib.optional spotifycfg.enable "$mainMod,S,exec,${lib.getExe spotifycfg.spicedSpotify}"
        );
      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = [
        "$mainMod,mouse:272,movewindow"
        "$mainMod,mouse:273,resizewindow"
      ];
      # Laptop multimedia keys for volume and LCD brightness
      bindel = [
        ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.5"
        ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute,exec,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp,exec,brightnessctl s 10%+"
        ",XF86MonBrightnessDown,exec,brightnessctl s 10%-"
      ];
      # Playerctl media keys
      bindl = [
        ",XF86AudioNext,exec,playerctl next"
        ",XF86AudioPause,exec,playerctl play-pause"
        ",XF86AudioPlay,exec,playerctl play-pause"
        ",XF86AudioPrev,exec,playerctl previous"
      ];

      windowrulev2 = [
        # Ignore maximize requests from apps.
        "suppressevent maximize,class:.*"
        # Fix some dragging issues with XWayland
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      ];
    };
  };
}
