{ inputs, ... }:
{
  nixpkgs.overlays = [
    # bring in opencode dev
    (final: prev: {
      opencode = (inputs.opencode.overlays.default final prev).opencode.overrideAttrs (oldAttrs: {
        # waiting for https://github.com/anomalyco/opencode/pull/11915
        version = final.lib.replaceString "-" "+" oldAttrs.version;
        __intentionallyOverridingVersion = true;
        patches = (oldAttrs.patches or [ ]) ++ [
          (final.fetchpatch2 {
            url = "https://github.com/anomalyco/opencode/commit/b546b174cc2c7065559cd33eea3b48673d569f7f.patch?full_index=1";
            hash = "sha256-vfRrSXlDXhsLNyTPwTDYJjCB1P0Xrwx7nNxjy9NYAig=";
          })
          (final.fetchpatch2 {
            url = "https://github.com/anomalyco/opencode/commit/a382d844935ea9e8b6d3bd4ef1554c9dedc706d8.patch?full_index=1";
            hash = "sha256-J3XsbU3qsycubmxpBJBEzy9TMYWPJOc3b003lW9AKSw=";
          })
        ];
      });
    })
  ];

  unify.modules.dev.home =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      programs.opencode.enable = lib.mkDefault true;
      home.shellAliases = lib.mkIf config.programs.opencode.enable {
        oc = lib.getExe config.programs.opencode.package;
      };
      # programs.gemini-cli.enable = lib.mkDefault true;

      systemd.user.services.opencode = {
        Unit = {
          Description = "Opencode AI CLI";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${lib.getExe config.programs.opencode.package} serve --port 40123";
          Restart = "on-failure";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };

      programs.waybar.settings.mainBar = {
        "custom/opencode" =
          let
            # FIXME: this is duplicated from waybar config, should be refactored
            # IDEA: write a "trayify" app that wraps an app in a system tray icon?
            icon = symbol: "<span font_desc='Font Awesome 7 Free'>${symbol}</span>";
          in
          {
            format = icon "";
            interval = "once";
            on-click = "${lib.getExe' pkgs.xdg-utils "xdg-open"} http://127.0.0.1:40123";
            tooltip = false;
          };
        # TODO: better ordering
        modules-right = lib.mkBefore [ "custom/opencode" ];
      };
    };

  persistence.programs.homeManager = {
    opencode = {
      directories = [ ".local/share/opencode" ];
    };
    gemini-cli = {
      directories = [ ".gemini" ];
    };
  };
}
