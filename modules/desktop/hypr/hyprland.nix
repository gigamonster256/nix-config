{
  flake.modules.nixos.desktop =
    { config, lib, ... }:
    {
      # If autoLogin is enabled, start hyprlock immediately on Hyprland startup
      home-manager.sharedModules = lib.optional config.services.displayManager.autoLogin.enable {
        wayland.windowManager.hyprland.settings.on = {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline "function()\n  hl.exec_cmd(\"hyprlock\")\nend")
          ];
        };
      };
    };

  flake.modules.homeManager.desktop =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib) getExe;

      terminal = "ghostty";
      mainMod = "SUPER";

      toggle-monitor-res = pkgs.writeShellApplication {
        name = "toggle-monitor-res";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          MON_SPEC="''${1-}"
          RES_A="''${2-}"
          RES_B="''${3-}"
          POSITIONING="''${4:-auto}"

          if [ -z "$MON_SPEC" ] || [ -z "$RES_A" ] || [ -z "$RES_B" ]; then
            echo "Usage: toggle-monitor-res <monitor> <res-a,scale-a> <res-b,scale-b> [positioning]" >&2
            exit 1
          fi

          MONITORS_JSON=$(hyprctl monitors -j)

          # Pull monitor info by description (desc:XYZ) or name (e.g. eDP-1)
          if [[ "$MON_SPEC" == desc:* ]]; then
            DESC_QUERY="''${MON_SPEC#desc:}"
            MONITOR_INFO=$(echo "$MONITORS_JSON" | jq --arg desc "$DESC_QUERY" 'map(select(.description | contains($desc))) | first')
          else
            MONITOR_INFO=$(echo "$MONITORS_JSON" | jq --arg name "$MON_SPEC" 'map(select(.name == $name)) | first')
          fi

          if [ -z "$MONITOR_INFO" ] || [ "$MONITOR_INFO" = "null" ]; then
            echo "Monitor '$MON_SPEC' not found" >&2
            exit 1
          fi

          CURRENT_RES=$(echo "$MONITOR_INFO" | jq -r '"\(.width)x\(.height)"')
          CURRENT_SCALE=$(echo "$MONITOR_INFO" | jq -r '.scale')

          # Extract resolution and scale from arguments, using current scale if not provided
          RES_A_RES="''${RES_A%,*}"
          RES_A_SCALE="''${CURRENT_SCALE}"
          if [[ "$RES_A" == *,* ]]; then
            RES_A_SCALE="''${RES_A#*,}"
          fi

          RES_B_RES="''${RES_B%,*}"
          RES_B_SCALE="''${CURRENT_SCALE}"
          if [[ "$RES_B" == *,* ]]; then
            RES_B_SCALE="''${RES_B#*,}"
          fi

          # Compare current resolution with resolution B (without refresh rate)
          RES_B_BASE="''${RES_B_RES%@*}"

          TARGET_RES="$RES_A_RES"
          TARGET_SCALE="$RES_A_SCALE"
          if [ "$CURRENT_RES" != "$RES_B_BASE" ]; then
            TARGET_RES="$RES_B_RES"
            TARGET_SCALE="$RES_B_SCALE"
          fi

          hyprctl keyword monitor "''${MON_SPEC}, ''${TARGET_RES}, ''${POSITIONING}, ''${TARGET_SCALE}"
        '';
      };

      bsod = pkgs.fetchurl {
        url = "https://upload.wikimedia.org/wikipedia/commons/5/56/Bsodwindows10.png";
        hash = "sha256-Sl3fpXygz/YiABjb9VG+FVEaF+nFV1EWdfoXwwQFJjU=";
      };

      hyprshot = getExe pkgs.hyprshot;
      hyprclip = "${hyprshot} --clipboard-only";

      # Lua config helpers
      mkLua = expr: lib.generators.mkLuaInline expr;
      mkBind = args: { _args = args; };
      mkBezierCurve = name: p1: p2: {
        _args = [
          name
          {
            type = "bezier";
            points = [
              p1
              p2
            ];
          }
        ];
      };
      mkAnim = leaf: speed: bezier: style: {
        _args = [
          (
            {
              inherit leaf;
              enabled = true;
              inherit speed bezier;
            }
            // lib.optionalAttrs (style != null) { inherit style; }
          )
        ];
      };
    in
    lib.mkMerge [
      {
        # TODO: re-enable when stylix updates
        stylix.targets.hyprland.enable = false;
        wayland.windowManager.hyprland = {
          configType = "lua";
          settings = {
            config = {
              ecosystem.no_update_news = true;

              general = {
                gaps_in = 2;
                gaps_out = 5;
                border_size = 2;
                resize_on_border = false;
                allow_tearing = false;
                layout = "dwindle";
                col = {
                  active_border = "rgb(89b4fa)";
                  inactive_border = "rgb(6c7086)";
                };
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
                  color = "rgba(1e1e2e99)";
                };
              };

              animations = {
                enabled = true;
              };

              dwindle = {
                preserve_split = true;
              };

              master = {
                new_status = "master";
              };

              group = {
                col = {
                  border_active = "rgb(89b4fa)";
                  border_inactive = "rgb(6c7086)";
                  border_locked_active = "rgb(94e2d5)";
                };
                groupbar = {
                  col = {
                    active = "rgb(89b4fa)";
                    inactive = "rgb(6c7086)";
                  };
                  text_color = "rgb(cdd6f4)";
                };
              };

              misc = {
                force_default_wallpaper = 0;
                disable_hyprland_logo = false;
                focus_on_activate = true;
                anr_missed_pings = 5;
                background_color = "rgb(1e1e2e)";
              };

              input = {
                kb_layout = "us";
                follow_mouse = 1;
                touchpad = {
                  natural_scroll = true;
                };
              };

              xwayland = {
                force_zero_scaling = true;
                create_abstract_socket = true;
              };
            };

            monitor = [
              {
                output = "desc:BOE";
                mode = "preferred";
                position = "auto";
                scale = 1.566667;
              }
              {
                output = "desc:GIGA-BYTE";
                mode = "preferred";
                position = "auto-center-left";
                scale = "auto";
              }
              {
                output = "desc:Dell Inc. DELL E2416H";
                mode = "preferred";
                position = "auto-center-up";
                scale = "auto";
              }
              {
                output = "";
                mode = "preferred";
                position = "auto";
                scale = "auto";
              }
            ];

            curve = [
              (mkBezierCurve "easeOutQuint" [ 0.23 1 ] [ 0.32 1 ])
              (mkBezierCurve "easeInOutCubic" [ 0.65 0.05 ] [ 0.36 1 ])
              (mkBezierCurve "linear" [ 0 0 ] [ 1 1 ])
              (mkBezierCurve "almostLinear" [ 0.5 0.5 ] [ 0.75 1 ])
              (mkBezierCurve "quick" [ 0.15 0 ] [ 0.1 1 ])
            ];

            animation = [
              (mkAnim "global" 10 "default" null)
              (mkAnim "border" 5.39 "easeOutQuint" null)
              (mkAnim "windows" 4.79 "easeOutQuint" null)
              (mkAnim "windowsIn" 4.1 "easeOutQuint" "popin 87%")
              (mkAnim "windowsOut" 1.49 "linear" "popin 87%")
              (mkAnim "fadeIn" 1.73 "almostLinear" null)
              (mkAnim "fadeOut" 1.46 "almostLinear" null)
              (mkAnim "fade" 3.03 "quick" null)
              (mkAnim "layers" 3.81 "easeOutQuint" null)
              (mkAnim "layersIn" 4 "easeOutQuint" "fade")
              (mkAnim "layersOut" 1.5 "linear" "fade")
              (mkAnim "fadeLayersIn" 1.79 "almostLinear" null)
              (mkAnim "fadeLayersOut" 1.39 "almostLinear" null)
              (mkAnim "workspaces" 1.94 "almostLinear" "fade")
              (mkAnim "workspacesIn" 1.21 "almostLinear" "fade")
              (mkAnim "workspacesOut" 1.94 "almostLinear" "fade")
            ];

            bind = builtins.concatLists [
              # Core window management
              [
                (mkBind [
                  "${mainMod} + RETURN"
                  (mkLua ''hl.dsp.exec_cmd("${terminal}")'')
                ])
                (mkBind [
                  "${mainMod} + C"
                  (mkLua "hl.dsp.window.close()")
                ])
                (mkBind [
                  "${mainMod} + F"
                  (mkLua "hl.dsp.window.fullscreen()")
                ])
                (mkBind [
                  "${mainMod} + M"
                  (mkLua "hl.dsp.exit()")
                ])
                (mkBind [
                  "${mainMod} + V"
                  (mkLua ''hl.dsp.window.float({ action = "toggle" })'')
                ])
                (mkBind [
                  "${mainMod} + P"
                  (mkLua "hl.dsp.window.pseudo()")
                ])
                (mkBind [
                  "${mainMod} + J"
                  (mkLua ''hl.dsp.layout("togglesplit")'')
                ])
              ]
              # Move focus
              [
                (mkBind [
                  "${mainMod} + left"
                  (mkLua ''hl.dsp.focus({ direction = "left" })'')
                ])
                (mkBind [
                  "${mainMod} + right"
                  (mkLua ''hl.dsp.focus({ direction = "right" })'')
                ])
                (mkBind [
                  "${mainMod} + up"
                  (mkLua ''hl.dsp.focus({ direction = "up" })'')
                ])
                (mkBind [
                  "${mainMod} + down"
                  (mkLua ''hl.dsp.focus({ direction = "down" })'')
                ])
              ]
              # Workspace & scratchpad navigation
              [
                (mkBind [
                  "${mainMod} + S"
                  (mkLua ''hl.dsp.workspace.toggle_special("magic")'')
                ])
                (mkBind [
                  "${mainMod} + SHIFT + S"
                  (mkLua ''hl.dsp.window.move({ workspace = "special:magic" })'')
                ])
                (mkBind [
                  "${mainMod} + mouse_down"
                  (mkLua ''hl.dsp.focus({ workspace = "e-1" })'')
                ])
                (mkBind [
                  "${mainMod} + mouse_up"
                  (mkLua ''hl.dsp.focus({ workspace = "e+1" })'')
                ])
              ]
              # Monitor resolution toggles & misc
              [
                # TODO: luafy
                (mkBind [
                  "${mainMod} + R"
                  (mkLua ''hl.dsp.exec_cmd("${getExe toggle-monitor-res} desc:GIGA-BYTE preferred 1920x1080 auto-center-left")'')
                ])
                (mkBind [
                  "${mainMod} + T"
                  (mkLua ''hl.dsp.exec_cmd("${getExe toggle-monitor-res} desc:BOE preferred 1920x1280")'')
                ])
                (mkBind [
                  "CTRL + ALT + Delete"
                  (mkLua ''hl.dsp.exec_cmd("${getExe pkgs.imv} -f ${bsod}")'')
                ])
              ]
              # Screenshots
              [
                (mkBind [
                  "${mainMod} + ALT + F3"
                  (mkLua ''hl.dsp.exec_cmd("${hyprclip} -m output")'')
                ])
                (mkBind [
                  "${mainMod} + ALT + F4"
                  (mkLua ''hl.dsp.exec_cmd("${hyprclip} -m window")'')
                ])
                (mkBind [
                  "${mainMod} + ALT + F5"
                  (mkLua ''hl.dsp.exec_cmd("${hyprclip} -m region")'')
                ])
                (mkBind [
                  "PRINT"
                  (mkLua ''hl.dsp.exec_cmd("${hyprclip} -m output")'')
                ])
                (mkBind [
                  "${mainMod} + PRINT"
                  (mkLua ''hl.dsp.exec_cmd("${hyprclip} -m window")'')
                ])
                (mkBind [
                  "${mainMod} + SHIFT + PRINT"
                  (mkLua ''hl.dsp.exec_cmd("${hyprclip} -m region")'')
                ])
              ]
              # Numeric workspaces (1-9)
              (
                let
                  workspaces = lib.lists.range 1 9;
                  switchBindings = map (
                    ws:
                    mkBind [
                      "${mainMod} + ${toString ws}"
                      (mkLua "hl.dsp.focus({ workspace = ${toString ws} })")
                    ]
                  ) workspaces;
                  moveBindings = map (
                    ws:
                    mkBind [
                      "${mainMod} + SHIFT + ${toString ws}"
                      (mkLua "hl.dsp.window.move({ workspace = ${toString ws} })")
                    ]
                  ) workspaces;
                in
                switchBindings ++ moveBindings
              )
              # Optional binds based on enabled programs
              (
                let
                  moduleBinds = { module, binds }: lib.optionals module.enable (binds module);
                  moduleKeybinds = [
                    {
                      module = config.programs.hyprlock;
                      binds = m: [
                        (mkBind [
                          "${mainMod} + L"
                          (mkLua ''hl.dsp.exec_cmd("${getExe m.package}")'')
                        ])
                      ];
                    }
                    {
                      module = config.programs.rofi;
                      binds = m: [
                        (mkBind [
                          "${mainMod} + space"
                          (mkLua ''hl.dsp.exec_cmd("${getExe m.finalPackage} -show drun")'')
                        ])
                      ];
                    }
                    {
                      module = config.programs.spotify;
                      binds = m: [
                        (mkBind [
                          "XF86AudioMedia"
                          (mkLua ''hl.dsp.exec_cmd("${getExe m.package}")'')
                        ])
                      ];
                    }
                  ];
                in
                builtins.concatMap moduleBinds moduleKeybinds
              )
              # Mouse binds
              [
                (mkBind [
                  "${mainMod} + mouse:272"
                  (mkLua "hl.dsp.window.drag()")
                  { mouse = true; }
                ])
                (mkBind [
                  "${mainMod} + mouse:273"
                  (mkLua "hl.dsp.window.resize()")
                  { mouse = true; }
                ])
                (mkBind [
                  "mouse:274"
                  (mkLua "hl.dsp.window.drag()")
                  { mouse = true; }
                ])
              ]
              # Locked binds (active when screen is locked)
              [
                (mkBind [
                  "XF86AudioMute"
                  (mkLua ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'')
                  { locked = true; }
                ])
                (mkBind [
                  "XF86AudioNext"
                  (mkLua ''hl.dsp.exec_cmd("playerctl next")'')
                  { locked = true; }
                ])
                (mkBind [
                  "XF86AudioPlay"
                  (mkLua ''hl.dsp.exec_cmd("playerctl play-pause")'')
                  { locked = true; }
                ])
                (mkBind [
                  "XF86AudioPause"
                  (mkLua ''hl.dsp.exec_cmd("playerctl play-pause")'')
                  { locked = true; }
                ])
                (mkBind [
                  "XF86AudioPrev"
                  (mkLua ''hl.dsp.exec_cmd("playerctl previous")'')
                  { locked = true; }
                ])
                (mkBind [
                  "switch:on:Lid Switch"
                  (mkLua ''hl.dsp.exec_cmd("hyprctl keyword monitor 'desc:BOE,disabled'")'')
                  { locked = true; }
                ])
                (mkBind [
                  "switch:off:Lid Switch"
                  (mkLua ''hl.dsp.exec_cmd("hyprctl keyword monitor 'desc:BOE,preferred,auto,1.566667'")'')
                  { locked = true; }
                ])
              ]
              # Repeating locked binds
              [
                (mkBind [
                  "XF86AudioRaiseVolume"
                  (mkLua ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1")'')
                  {
                    locked = true;
                    repeating = true;
                  }
                ])
                (mkBind [
                  "XF86AudioLowerVolume"
                  (mkLua ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'')
                  {
                    locked = true;
                    repeating = true;
                  }
                ])
                (mkBind [
                  "XF86AudioMicMute"
                  (mkLua ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")'')
                  {
                    locked = true;
                    repeating = true;
                  }
                ])
                (mkBind [
                  "XF86MonBrightnessUp"
                  (mkLua ''hl.dsp.exec_cmd("brightnessctl s 10%+")'')
                  {
                    locked = true;
                    repeating = true;
                  }
                ])
                (mkBind [
                  "XF86MonBrightnessDown"
                  (mkLua ''hl.dsp.exec_cmd("brightnessctl s 10%-")'')
                  {
                    locked = true;
                    repeating = true;
                  }
                ])
              ]
            ];

            window_rule = [
              {
                name = "suppress-maximize-events";
                match = {
                  class = ".*";
                };
                suppress_event = "maximize";
              }
              {
                name = "fix-xwayland-drags";
                match = {
                  class = "^$";
                  title = "^$";
                  xwayland = true;
                  float = true;
                  fullscreen = false;
                  pin = false;
                };
                no_focus = true;
              }
              {
                name = "no-gaps-wtv1";
                match = {
                  float = false;
                  workspace = "w[tv1]";
                };
                border_size = 0;
              }
              {
                name = "no-gaps-f1";
                match = {
                  float = false;
                  workspace = "f[1]";
                };
                border_size = 0;
              }
            ];

            workspace_rule = [
              {
                workspace = "w[tv1]";
                gaps_out = 0;
                gaps_in = 0;
              }
              {
                workspace = "f[1]";
                gaps_out = 0;
                gaps_in = 0;
              }
            ];

            layer_rule = [
              {
                match = {
                  namespace = "selection";
                };
                no_anim = true;
              }
            ];
          };
        };
      }
    ];
}
