{
  unify.modules.desktop.nixos =
    { config, lib, ... }:
    {
      # immediately log out if autoLogin is enabled - basically use the lock screen as a login screen
      home-manager.sharedModules = lib.optional config.services.displayManager.autoLogin.enable {
        wayland.windowManager.hyprland.settings.exec-once = [ "hyprlock" ];
      };
    };

  unify.modules.desktop.home =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib)
        mkMerge
        getExe
        optionals
        ;

      toggle-monitor-res = pkgs.writeShellApplication {
        name = "toggle-monitor-res";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          # Get current resolution of GIGA-BYTE monitor
          CURRENT_RES=$(hyprctl monitors -j | jq -r '.[] | select(.description | contains("GIGA-BYTE")) | "\(.width)x\(.height)"')

          # Toggle the resolution
          if [ "$CURRENT_RES" = "1920x1080" ]; then
              # Switch to preferred
              hyprctl keyword monitor "desc:GIGA-BYTE,preferred,auto-center-left,auto"
          else
              # Switch to 1080p
              hyprctl keyword monitor "desc:GIGA-BYTE,1920x1080,auto-center-left,auto"
          fi
        '';
      };
    in
    mkMerge [
      {
        wayland.windowManager.hyprland = {
          settings = {
            "$terminal" = "ghostty";
            "$mainMod" = "SUPER";
            ecosystem.no_update_news = true;
            monitor = [
              "desc:BOE,preferred,auto,1.566667" # framework monitor
              "desc:GIGA-BYTE,preferred,auto-center-left,auto" # no hdr on dockcase ",bitdepth,10" # home monitor
              "desc:Dell Inc. DELL E2416H,preferred,auto-center-up,auto" # work monitor
              ",preferred,auto,auto"
            ];
            exec-once = [ ];
            xwayland = {
              force_zero_scaling = true;
              create_abstract_socket = true; # chirp (wxPython) hangs trying to connect to /tmp/.X11-unix/X0 without this
            };
            env = [ ];
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
              # switch to an app when it is activated (things like clicking a notification or tray icon)
              focus_on_activate = true;
              # how many pings an app has to miss before the "app not responding" dialog pops up
              anr_missed_pings = 5;
            };

            input = {
              kb_layout = "us";
              follow_mouse = 1;
              touchpad.natural_scroll = true;
            };

            # https://wiki.hypr.land/Configuring/Gestures
            # gestures = [];

            # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
            bind = builtins.concatLists [
              [
                "$mainMod,Return,exec,$terminal"
                "$mainMod,C,killactive"
                "$mainMod,F,fullscreen"
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
                "$mainMod,mouse_down,workspace,e-1"
                "$mainMod,mouse_up,workspace,e+1"
                # Toggle external monitor resolution
                "$mainMod,R,exec,${getExe toggle-monitor-res}"
              ]
              (
                # screenshots using hyprshot
                let
                  hyprshot = getExe pkgs.hyprshot;
                  hyprclip = "${hyprshot} --clipboard-only";
                in
                [
                  # macOS shortcut inspired
                  "$mainMod ALT,F3,exec,${hyprclip} -m output"
                  "$mainMod ALT,F4,exec,${hyprclip} -m window"
                  "$mainMod ALT,F5,exec,${hyprclip} -m region"
                  # printscreen style
                  ",PRINT,exec,${hyprclip} -m output"
                  "$mainMod,PRINT,exec,${hyprclip} -m window"
                  "$mainMod SHIFT,PRINT,exec,${hyprclip} -m region"
                ]
              )
              (
                # Switch workspaces with mainMod + [1-9]
                # $mainMod,1,workspace,1
                # Move active window to a workspace with mainMod + SHIFT + [1-9]
                # $mainMod SHIFT,1,movetoworkspace,1
                let
                  workspaces = map toString (lib.lists.range 1 9);
                  switchModifier = "$mainMod";
                  moveModifier = "$mainMod SHIFT";
                  switchBindings = map (ws: "${switchModifier},${ws},workspace,${ws}") workspaces;
                  moveBindings = map (ws: "${moveModifier},${ws},movetoworkspace,${ws}") workspaces;
                in
                switchBindings ++ moveBindings
              )
              (
                # keybinds if other modules are enabled
                let
                  moduleBinds = { module, binds }: optionals module.enable (binds module);
                  moduleKeybinds = [
                    {
                      module = config.programs.hyprlock;
                      binds = m: [
                        "$mainMod,L,exec,${getExe m.package}"
                      ];
                    }
                    {
                      module = config.programs.rofi;
                      binds =
                        m:
                        let
                          rofi = getExe m.finalPackage;
                        in
                        [
                          "$mainMod,space,exec,${rofi} -show drun"
                          # other rofi modes? (emoji picker etc...)
                        ];
                    }
                    {
                      module = config.programs.spotify;
                      binds = m: [
                        ",XF86AudioMedia,exec,${getExe m.package}"
                      ];
                    }
                  ];
                in
                builtins.concatMap moduleBinds moduleKeybinds
              )
            ];

            # mouse binds
            bindm = [
              # Move/resize windows with mainMod + LMB/RMB and dragging
              "$mainMod,mouse:272,movewindow"
              "$mainMod,mouse:273,resizewindow"

              # middle mouse move
              ",mouse:274,movewindow"
            ];

            # binds that work when screen is locked
            bindl = [
              # mute key
              ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
              # Playerctl media keys
              ",XF86AudioNext,exec,playerctl next"
              ",XF86AudioPlay,exec,playerctl play-pause"
              ",XF86AudioPause,exec,playerctl play-pause"
              ",XF86AudioPrev,exec,playerctl previous"
            ];

            # binds that repeat (and active when screen locked)
            bindel = [
              # Laptop multimedia keys for volume and LCD brightness
              ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1"
              ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
              ",XF86AudioMicMute,exec,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
              ",XF86MonBrightnessUp,exec,brightnessctl s 10%+"
              ",XF86MonBrightnessDown,exec,brightnessctl s 10%-"
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
    ];
}
