{
  flake.modules.nixos.desktop =
    { config, ... }:
    {
      home-manager.sharedModules = [
        {
          programs.hyprlock.settings.auth.fingerprint.enabled = config.services.fprintd.enable;
        }
      ];
    };

  flake.modules.homeManager.desktop =
    {
      lib,
      config,
      ...
    }:
    {
      programs.hyprlock = {
        enable = lib.mkDefault config.wayland.windowManager.hyprland.enable;
        settings = {
          general = {
            hide_cursor = true;
          };
          animations = {
            enabled = true;
            bezier = "linear,1,1,0,0";
            animation = [
              "fadeIn,1,5,linear"
              "fadeOut,1,5,linear"
              "inputFieldDots,1,2,linear"
            ];
          };
          background = {
            monitor = "";
            path = "screenshot";
            blur_passes = 3;
          };

          # fingerprint `enabled` is set via the NixOS shared module
          # (based on services.fprintd.enable); only messaging is configured here
          auth.fingerprint = {
            ready_message = "Scan fingerprint to unlock";
            present_message = "Scanning...";
            retry_delay = 250; # in milliseconds
          };

          input-field = {
            monitor = "";
            # size = 20%, 5%
            outline_thickness = 3;
            fade_on_empty = false;
            # placeholder_text = Input password...
            # fail_text = $PAMFAIL

            dots_spacing = 0.3;

            position = "0, -20";
            halign = "center";
            valign = "center";
          };

          # TIME
          label = [
            {
              monitor = "";
              text = "$TIME12";
              font_size = 90;

              position = "-30, 0";
              halign = "right";
              valign = "top";
            }

            # DATE
            {
              monitor = "";
              text = "cmd[update:60000] date +\"%A, %d %B %Y\"";
              font_size = 25;

              position = "-30, -150";
              halign = "right";
              valign = "top";
            }

            # FINGERPRINT FEEDBACK
            {
              monitor = "";
              text = "$FPRINTPROMPT";
              # base05 is the foreground color (same as stylix's input-field font_color)
              color = "rgba(${config.lib.stylix.colors.base05}cc)";
              font_size = 16;

              position = "0, -95";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };
    };
}
