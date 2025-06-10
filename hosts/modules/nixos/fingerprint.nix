{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    getExe
    mkOption
    mkIf
    types
    ;
  cfg = config.laptop;
in
{
  options.laptop.lidDevice = mkOption {
    type = with types; nullOr str;
    default = null;
  };

  config =
    mkIf
      (config.services.fprintd.enable && config.facter.report.hardware.system.form_factor == "laptop")
      {
        assertions = [
          {
            assertion = cfg.lidDevice != null;
            message = "laptop.lidDevice must be set when fprintd is enabled on a laptop.";
          }
        ];
        # do not start fprintd if lid is closed
        systemd.services.fprintd.serviceConfig.ExecStartPre =
          "${getExe pkgs.gnugrep} -q open /proc/acpi/button/lid/${cfg.lidDevice}/state";

        # start/stop fprintd when lid is opened/closed
        services.acpid = {
          enable = true;
          lidEventCommands = ''
            state=$(echo "$1" | cut -d " " -f 3)
            case "$state" in
                open)
                    systemctl start fprintd.service
                    ;;
                close)
                    systemctl stop fprintd.service
                    ;;
                *)
            esac
          '';
        };
      };
}
