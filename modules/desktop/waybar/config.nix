{
  unify.modules.desktop.home =
    {
      lib,
      pkgs,
      config,
      systemConfig,
      ...
    }:
    {
      programs.waybar.settings.mainBar =
        let
          inherit (lib)
            getExe
            mkIf
            ;
          icon = symbol: "<span font_desc='Font Awesome 7 Free'>${symbol}</span>";
          textIcon = text: i: "${text} ${icon i}";
          # TODO: refactor
          vpnInterfaceNames =
            if systemConfig == null then
              [ ]
            else
              builtins.concatMap builtins.attrNames (
                with systemConfig.networking;
                [
                  openconnect.interfaces
                  wg-quick.interfaces
                ]
              );
        in
        {
          layer = "top";
          position = "top";
          height = 24;
          modules-left = [
            "hyprland/workspaces"
          ];
          modules-center = [
            "hyprland/window"
          ];
          modules-right = [
            "wireplumber"
            "network"
          ]
          ++ lib.optional (vpnInterfaceNames != [ ]) "custom/vpn"
          ++ [
            "cpu"
            "battery"
            "power-profiles-daemon"
            "tray"
            "bluetooth"
            "clock"
          ]
          ++ lib.optional config.services.fnott.enable "custom/fnott"
          ++ [
            "idle_inhibitor"
            "custom/wlogout"
          ];
          "hyprland/workspaces" = {
            all-outputs = false;
            disable-scroll = true;
            format = icon "{icon}";
            format-icons = {
              default = "";
              active = "";
              urgent = "";
            };
          };
          wireplumber = {
            reverse-scrolling = 1;
            format = textIcon "{volume}%" "{icon}";
            format-muted = textIcon "MUTE" "";
            format-icons = [
              ""
              ""
            ];
            on-click = getExe pkgs.pwvucontrol;
          };
          network = {
            format-disconnected = textIcon "Disconnected" "⚠";
            format-ethernet = textIcon "{ipaddr}" "";
            format-wifi = textIcon "{essid}" "";
          };
          cpu = {
            format = textIcon "{usage}%" "";
          };
          memory = {
            format = textIcon "{}%" "";
          };
          power-profiles-daemon = {
            format = icon "{icon}";
            format-icons = {
              default = "";
              performance = "";
              balanced = "";
              power-saver = "";
            };
          };
          battery = {
            format = textIcon "{capacity}%" "{icon}";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
            format-charging = textIcon "{capacity}%" "";
            states = {
              critical = 15;
              warning = 30;
            };
          };
          tray = {
            spacing = 10;
          };
          clock = {
            format = "{:%I:%M}"; # 12 hour time
            tooltip-format = "{:%A %Y-%m-%d}";
          };
          idle_inhibitor = {
            format = icon "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };
          bluetooth = {
            # format = brandIcon "{icon}";
            format-icons = {
              connected = "";
              disconnected = "";
            };
            on-click = "${getExe config.programs.ghostty.package} -e ${getExe pkgs.bluetui}";
          };
          "custom/fnott" = mkIf config.services.fnott.enable {
            format = icon "{text}";
            tooltip = false;
            interval = 5;
            exec = ''
              transient_unit="$XDG_RUNTIME_DIR/systemd/transient/fnott.service"
              if [ -L "$transient_unit" ]; then
                echo '{"text": ""}' # bell-slash (disabled)
              else
                echo '{"text": ""}' # bell (active)
              fi
            '';
            return-type = "json";
            on-click = ''
              transient_unit="$XDG_RUNTIME_DIR/systemd/transient/fnott.service"
              if [ -L "$transient_unit" ]; then
                rm "$transient_unit"
                systemctl --user daemon-reload
              else
                systemctl --user stop fnott.service
                ln -sf /dev/null "$transient_unit"
                systemctl --user daemon-reload
              fi
            '';
          };
          "custom/vpn" = mkIf (vpnInterfaceNames != [ ]) {
            format = "{text}";
            exec = getExe (
              pkgs.waybar-vpn-status.override {
                interfaces = vpnInterfaceNames;
              }
            );
            interval = 5;
            return-type = "json";
          };
          "custom/wlogout" = {
            format = icon "";
            interval = "once";
            on-click = getExe config.programs.wlogout.package;
            tooltip = false; # disable tooltip
          };
        };
    };
}
