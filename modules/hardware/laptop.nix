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
      isLaptop =
        config.hardware.facter.enable
        && (config.hardware.facter.report.hardware.system.form_factor or null) == "laptop";
    in
    {
      options.laptop.lidDevice = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };

      config = lib.mkMerge [
        (lib.mkIf (config.services.fprintd.enable && isLaptop) {
          assertions = [
            {
              assertion = cfg.lidDevice != null;
              message = "laptop.lidDevice must be set when fprintd is enabled on a laptop.";
            }
          ];

          # add other services as needed
          # alternative would be to integrate into the pamOpts defaults as a new auth rule
          # to automatically apply to all pam services that don't opt out with useDefaultRules = false
          # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/security/pam.nix
          security.pam.services = lib.genAttrs [ "sudo" ] (
            service:
            let
              fprintRule = config.security.pam.services.${service}.rules.auth.fprintd;
            in
            {
              rules.auth.laptop-lid-closed = {
                inherit (fprintRule) enable;
                order = fprintRule.order - 1; # must be right before the fprintd rule
                control = "[success=1 default=ignore]";
                modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
                args = [
                  "quiet"
                  "${pkgs.writeShellScript "laptop-lid-closed" ''
                    ${lib.getExe pkgs.gnugrep} -q closed /proc/acpi/button/lid/${cfg.lidDevice}/state
                  ''}"
                ];
              };
            }
          );

          # Hibernation tears down every USB device, so on resume the reader is
          # re-enumerated under a new bus/device number. fprintd still holds the
          # old libusb handle and drops the device with
          # `USB error on device ... : No such device` (getcap errno=19), leaving
          # it with no fingerprint device until the daemon restarts.
          #
          # This unit runs after systemd-hibernate.service has returned (the
          # target is ordered after the sleep service) and stays inactive
          # afterwards, so it fires on every resume.
          systemd.services.fprintd-resume = {
            description = "Restart fprintd after resuming from hibernation";

            after = [
              "hibernate.target"
              "hybrid-sleep.target"
            ];
            wantedBy = [
              "hibernate.target"
              "hybrid-sleep.target"
            ];

            serviceConfig = {
              Type = "oneshot";
              # let the kernel finish re-enumerating and resetting the reader
              ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
              ExecStart = "${config.systemd.package}/bin/systemctl try-restart fprintd.service";
            };
          };
        })
        {
          services.automatic-timezoned.enable = lib.mkDefault true;
        }
        (lib.mkIf isLaptop {
          # power-profiles-daemon drives the waybar profile widget; its
          # battery-aware EPP tuning reacts to UPower's OnBattery signal,
          # so UPower must be running for it to do anything.
          services.power-profiles-daemon.enable = true;
          services.upower.enable = true;
        })
      ];
    };
}
