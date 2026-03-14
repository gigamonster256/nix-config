{
  flake.modules.nixos.laptop =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.laptop;
    in
    {
      options.laptop.lidDevice = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };

      config = lib.mkMerge [
        (lib.mkIf
          (
            config.services.fprintd.enable
            && config ? facter
            && config.facter.report.hardware.system.form_factor == "laptop"
          )
          {
            assertions = [
              {
                assertion = cfg.lidDevice != null;
                message = "laptop.lidDevice must be set when fprintd is enabled on a laptop.";
              }
            ];
            # do not start fprintd if lid is closed
            systemd.services.fprintd.serviceConfig.ExecStartPre =
              "${lib.getExe pkgs.gnugrep} -q open /proc/acpi/button/lid/${cfg.lidDevice}/state";

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
          }
        )
        {
          services.automatic-timezoned.enable = lib.mkDefault true;
        }
      ];
    };
}
