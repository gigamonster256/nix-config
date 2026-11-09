{
  flake.modules.nixos.framework-fingerprint-led-blink =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.framework-fingerprint-led-blink;
      inherit (lib) mkOption types;

      # nixos-facter exposes the SMBIOS vendor strings. Framework sets both the
      # system and board manufacturer to "Framework".
      isFramework =
        let
          report = config.hardware.facter.report or { };
          smbios = report.smbios or { };
          manufacturers = [
            (smbios.system.manufacturer or "")
            (smbios.board.manufacturer or "")
          ];
        in
        config.hardware.facter.enable
        && lib.any (vendor: lib.hasInfix "framework" (lib.toLower vendor)) manufacturers;
    in
    {
      options.services.framework-fingerprint-led-blink = {
        enable = mkOption {
          type = types.bool;
          default = isFramework;
          description = ''
            Whether to blink the power-button LED while fprintd waits for a
            fingerprint. Defaults to true when the nixos-facter report
            identifies the machine as a Framework device.
          '';
        };

        package = mkOption {
          type = types.package;
          default = pkgs.framework-fingerprint-led-blink;
          defaultText = lib.literalMD "framework-fingerprint-led-blink built against the system `pkgs`";
          description = ''
            The watcher package. The script reads its tunables from the
            `FINGERPRINT_LED_BLINK_*` environment variables, which this module
            sets from the options below.
          '';
        };

        led = mkOption {
          type = types.str;
          default = "chromeos:white:power";
          example = "chromeos:multicolor:charging";
          description = ''
            LED name under {file}`/sys/class/leds`. The default is the power
            button (which houses the fingerprint reader) on Framework laptops,
            exposed by the `leds_cros_ec` driver. The LED is handed back to
            the embedded controller with the `chromeos-auto` trigger when
            blinking stops.
          '';
        };

        onSeconds = mkOption {
          type = types.numbers.positive;
          default = 0.25;
          description = "Seconds the LED stays on per blink.";
        };

        offSeconds = mkOption {
          type = types.numbers.positive;
          default = 0.25;
          description = "Seconds the LED stays off per blink.";
        };

        maxBlinkSeconds = mkOption {
          type = types.numbers.positive;
          default = 60;
          description = ''
            Safety net: stop blinking after this long even if no stop signal
            was seen.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        # nothing to watch without it
        services.fprintd.enable = lib.mkDefault true;

        systemd.services.framework-fingerprint-led-blink = {
          description = "Blink Framework power-button LED while fprintd waits for a fingerprint";
          after = [ "dbus.service" ];
          wantedBy = [ "multi-user.target" ];

          environment = {
            FINGERPRINT_LED_BLINK_LED = cfg.led;
            FINGERPRINT_LED_BLINK_ON_S = toString cfg.onSeconds;
            FINGERPRINT_LED_BLINK_OFF_S = toString cfg.offSeconds;
            FINGERPRINT_LED_BLINK_MAX_S = toString cfg.maxBlinkSeconds;
          };

          serviceConfig = {
            Type = "simple";
            ExecStart = lib.getExe cfg.package;

            # The script restores the LED on SIGTERM itself; this covers
            # SIGKILL and crashes. The leading "-" means a missing LED must not
            # fail the unit.
            ExecStopPost = "-${pkgs.runtimeShell} -c 'echo chromeos-auto > /sys/class/leds/${cfg.led}/trigger'";

            Restart = "on-failure";
            RestartSec = 2;

            # Must be uid 0: the system bus only lets root call BecomeMonitor,
            # and the LED sysfs files are root-owned. No capabilities are
            # needed for either, so drop them all.
            CapabilityBoundingSet = "";
            NoNewPrivileges = true;

            # Leaves /sys writable (ProtectKernelTunables would not).
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;

            # The system bus is a path socket, which survives a private netns.
            PrivateNetwork = true;
            RestrictAddressFamilies = [ "AF_UNIX" ];

            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectProc = "invisible";
            ProcSubset = "pid";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [ "@system-service" ];
            UMask = "0077";
          };
        };
      };
    };
}
