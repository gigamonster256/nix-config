{ config, ... }:
{
  programs.wlogout = {
    enable = config.wayland.windowManager.hyprland.enable;
    # TODO: fix hardcoded colors
    style =
      let
        inherit (config.lib.stylix.colors.withHashtag) base05 base0E;
        iconPath = "${config.programs.wlogout.package}/share/wlogout/icons";
      in
      ''
        /* Wlogout theme based on Catppuccin Mocha mauve plus stylix */

        * {
            background-image: none;
            box-shadow: none;
        }

        window {
            background-color: rgba(30, 30, 46, 0.90);
        }

        button {
            border-radius: 0;
            border-color: ${base0E};
            text-decoration-color: ${base05};
            color: ${base05};
            background-color: #181825;
            border-style: solid;
            border-width: 1px;
            background-repeat: no-repeat;
            background-position: center;
            background-size: 25%;
        }

        button:focus, button:active, button:hover {
            /* 20% Overlay 2, 80% mantle */
            background-color: rgb(48, 50, 66);
            outline-style: none;
        }

        /* Icons from original wlogout */

        #lock {
            background-image: url("${iconPath}/lock.png");
        }

        #logout {
            background-image: url("${iconPath}/logout.png");
        }

        #suspend {
            background-image: url("${iconPath}/suspend.png");
        }

        #hibernate {
            background-image: url("${iconPath}/hibernate.png");
        }

        #shutdown {
            background-image: url("${iconPath}/shutdown.png");
        }

        #reboot {
            background-image: url("${iconPath}/reboot.png");
        }
      '';
  };
}
