{ inputs, ... }:
{
  nixpkgs.overlays = [
    # bring in opencode dev
    (final: _prev: {
      inherit (inputs.opencode.packages.${final.stdenv.hostPlatform.system}) opencode;
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
