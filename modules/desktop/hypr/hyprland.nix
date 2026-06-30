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
      terminal = config.programs.ghostty.openCommand;
      mainMod = "SUPER";

      bsod = pkgs.fetchurl {
        url = "https://upload.wikimedia.org/wikipedia/commons/5/56/Bsodwindows10.png";
        hash = "sha256-Sl3fpXygz/YiABjb9VG+FVEaF+nFV1EWdfoXwwQFJjU=";
      };

      # Lua config helpers
      mkLua = expr: lib.generators.mkLuaInline expr;
      mkBind = args: { _args = args; };
      mkExec =
        bind: cmd: args: rules: extra:
        mkBind (
          [
            bind
            # TODO: escapeShellArgs doesnt seem right and I don't like the inline Lua generator for the attrset
            (mkLua ''hl.dsp.exec_cmd("${cmd} ${lib.escapeShellArgs args}", ${lib.generators.toLua { } rules})'')
          ]
          ++ extra
        );
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
      mkToggleMonitor =
        mon_spec: res_a: res_b: positioning:
        let
          res_a_res = lib.head (lib.splitString "," res_a);
          res_b_res = lib.head (lib.splitString "," res_b);
          res_b_base = lib.head (lib.splitString "@" res_b_res);
        in
        mkLua ''
          function()
            local mon = hl.get_monitor("${mon_spec}")
            if not mon then return end

            local current_res = mon.width .. "x" .. mon.height
            local current_scale = mon.scale or 1.0
            local target_res

            if current_res == "${res_b_base}" then
              target_res = "${res_a_res}"
            else
              target_res = "${res_b_res}"
            end

            hl.monitor({
              output = mon.name,
              mode = target_res,
              position = "${positioning}",
              scale = current_scale,
            })
          end
        '';
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
                (mkExec "${mainMod} + RETURN" terminal [ ] { } [ ])
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
              (
                let
                  mkFocus =
                    key: direction:
                    mkBind [
                      "${mainMod} + ${key}"
                      (mkLua ''hl.dsp.focus({ direction = "${direction}" })'')
                    ];
                in
                [
                  (mkFocus "left" "left")
                  (mkFocus "right" "right")
                  (mkFocus "up" "up")
                  (mkFocus "down" "down")
                ]
              )
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
                (mkBind [
                  "${mainMod} + R"
                  (mkToggleMonitor "desc:GIGA-BYTE" "preferred" "1920x1080" "auto-center-left")
                ])
                (mkBind [
                  "${mainMod} + T"
                  (mkToggleMonitor "desc:BOE" "preferred" "1920x1280" "auto")
                ])
                (mkExec "CTRL + ALT + Delete" (lib.getExe pkgs.imv) [ bsod ] {
                  fullscreen = true;
                } [ ])
              ]
              # Screenshots
              (
                let
                  mkScreenshot =
                    bind: mode: mkExec bind (lib.getExe pkgs.hyprshot) [ "--clipboard-only" "--mode" mode ] { } [ ];
                in
                [
                  (mkScreenshot "${mainMod} + ALT + F3" "output")
                  (mkScreenshot "${mainMod} + ALT + F4" "window")
                  (mkScreenshot "${mainMod} + ALT + F5" "region")
                  (mkScreenshot "PRINT" "output")
                  (mkScreenshot "${mainMod} + PRINT" "window")
                  (mkScreenshot "${mainMod} + SHIFT + PRINT" "region")
                ]
              )
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
                        (mkExec "${mainMod} + L" (lib.getExe m.package) [ ] { } [ ])
                      ];
                    }
                    {
                      module = config.programs.rofi;
                      binds = m: [
                        (mkExec "${mainMod} + space" (lib.getExe m.finalPackage) [ "-show" "drun" ] { } [ ])
                      ];
                    }
                    {
                      module = config.programs.spotify;
                      binds = m: [
                        (mkExec "XF86AudioMedia" (lib.getExe m.package) [ ] { } [ ])
                      ];
                    }
                  ];
                in
                builtins.concatMap moduleBinds moduleKeybinds
              )
              # Mouse binds
              (
                let
                  mkMouse =
                    bind: cmd:
                    mkBind [
                      bind
                      cmd
                      { mouse = true; }
                    ];
                in
                [
                  (mkMouse "${mainMod} + mouse:272" (mkLua "hl.dsp.window.drag()"))
                  (mkMouse "${mainMod} + mouse:273" (mkLua "hl.dsp.window.resize()"))
                  (mkMouse "mouse:274" (mkLua "hl.dsp.window.drag()"))
                ]
              )
              # Locked binds (active when screen is locked)
              (
                let
                  locked = {
                    locked = true;
                  };
                  mkLocked =
                    bind: cmd: args:
                    mkExec bind cmd args { } (lib.singleton locked);
                in
                [
                  (mkLocked "XF86AudioMute" "wpctl" [
                    "set-mute"
                    "@DEFAULT_AUDIO_SINK@"
                    "toggle"
                  ])
                  (mkLocked "XF86AudioNext" "playerctl" [ "next" ])
                  (mkLocked "XF86AudioPlay" "playerctl" [ "play-pause" ])
                  (mkLocked "XF86AudioPause" "playerctl" [ "play-pause" ])
                  (mkLocked "XF86AudioPrev" "playerctl" [ "previous" ])
                  (mkBind [
                    "switch:on:Lid Switch"
                    (mkLua "function()\nhl.monitor({ output = 'desc:BOE', disabled = true })\nend")
                    locked
                  ])
                  (mkBind [
                    "switch:off:Lid Switch"
                    (mkLua "function()\nhl.monitor({ output = 'desc:BOE', disabled = false })\nend")
                    locked
                  ])
                ]
              )
              # Repeating locked binds
              (
                let
                  lockedRepeating = lib.singleton {
                    locked = true;
                    repeating = true;
                  };
                  mkLockedRepeat =
                    bind: cmd: args:
                    mkExec bind cmd args { } lockedRepeating;
                in
                [
                  (mkLockedRepeat "XF86AudioRaiseVolume" "wpctl" [
                    "set-volume"
                    "@DEFAULT_AUDIO_SINK@"
                    "5%+"
                    "--limit"
                    "1"
                  ])
                  (mkLockedRepeat "XF86AudioLowerVolume" "wpctl" [
                    "set-volume"
                    "@DEFAULT_AUDIO_SINK@"
                    "5%-"
                  ])
                  (mkLockedRepeat "XF86AudioMicMute" "wpctl" [
                    "set-mute"
                    "@DEFAULT_AUDIO_SOURCE@"
                    "toggle"
                  ])
                  (mkLockedRepeat "XF86MonBrightnessUp" "brightnessctl" [
                    "set"
                    "10%+"
                  ])
                  (mkLockedRepeat "XF86MonBrightnessDown" "brightnessctl" [
                    "set"
                    "10%-"
                  ])
                ]
              )
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
