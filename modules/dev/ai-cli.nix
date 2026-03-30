{ inputs, ... }:
{
  nixpkgs.overlays = [
    # bring in opencode dev
    inputs.opencode.overlays.default
  ];

  flake.modules.homeManager.dev =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      programs.opencode = {
        enable = lib.mkDefault true;
        web.enable = lib.mkDefault config.programs.opencode.enable;
        # TODO: port option so other modules can reference it?
        web.extraArgs = [
          "--port" "40123"
        ];
      };

      home.shellAliases = lib.mkIf config.programs.opencode.enable {
        oc = lib.getExe config.programs.opencode.package;
      };
      # programs.gemini-cli.enable = lib.mkDefault true;

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
