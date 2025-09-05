{
  lib,
  writeShellApplication,
  systemd,
  symlinkJoin,
  services ? [ ],
}:
let
  # Individually overridable builders
  mkOn =
    {
      services ? [ ],
    }:
    writeShellApplication {
      name = "vpn-on";
      runtimeInputs = [ systemd ];
      text = ''
        # Default service list from build-time config (without .service suffix)
        DEFAULT_SERVICES=( ${lib.concatMapStringsSep " " lib.escapeShellArg services} )

        # Allow overriding via CLI args; else use build-time list
        if [ "$#" -gt 0 ]; then
          SERVICE_NAMES=("$@")
        else
          SERVICE_NAMES=("''${DEFAULT_SERVICES[@]}")
        fi

        if [ "''${#SERVICE_NAMES[@]}" -eq 0 ]; then
          echo "No service names provided." >&2
          exit 1
        fi

        unit_for() {
          local base="$1"
          local unit="""$base"".service"
          if systemctl cat "$unit" >/dev/null 2>&1; then
            echo "$unit"
            return 0
          fi
          return 1
        }

        echo "Select a VPN service to start:"
        PS3="> "
        select choice in "''${SERVICE_NAMES[@]}"; do
          if [ -n "''${choice:-}" ]; then
            break
          fi
          echo "Invalid selection" >&2
        done

        unit="$(unit_for "$choice" || true)"
        if [ -z "$unit" ]; then
          echo "No systemd service unit found for '$choice'." >&2
          exit 1
        fi

        echo "Starting $unit ..."
        systemctl start "$unit"
        if systemctl is-active --quiet "$unit"; then
          echo "Started: $unit"
        else
          echo "Failed to start: $unit" >&2
          exit 1
        fi
      '';
    };

  mkOff =
    {
      services ? [ ],
    }:
    writeShellApplication {
      name = "vpn-off";
      runtimeInputs = [ systemd ];
      text = ''
        DEFAULT_SERVICES=( ${lib.concatMapStringsSep " " lib.escapeShellArg services} )

        if [ "$#" -gt 0 ]; then
          SERVICE_NAMES=("$@")
        else
          SERVICE_NAMES=("''${DEFAULT_SERVICES[@]}")
        fi

        unit_for() {
          local base="$1"
          local unit="""$base"".service"
          if systemctl cat "$unit" >/dev/null 2>&1; then
            echo "$unit"
            return 0
          fi
          return 1
        }

        active_names=()
        for name in "''${SERVICE_NAMES[@]}"; do
          unit="$(unit_for "$name" || true)"
          if [ -n "$unit" ] && systemctl is-active --quiet "$unit"; then
            active_names+=("$name")
          fi
        done

        if [ "''${#active_names[@]}" -eq 0 ]; then
          echo "No active VPN units among provided names." >&2
          exit 1
        fi

        if [ "''${#active_names[@]}" -eq 1 ]; then
          choice="''${active_names[0]}"
          echo "Only one active VPN: $choice"
        else
          echo "Select a VPN service to stop:"
          PS3="> "
          select choice in "''${active_names[@]}"; do
            if [ -n "''${choice:-}" ]; then
              break
            fi
            echo "Invalid selection" >&2
          done
        fi

        unit="$(unit_for "$choice")"
        echo "Stopping $unit ..."
        systemctl stop "$unit"
        if systemctl is-active --quiet "$unit"; then
          echo "Failed to stop: $unit" >&2
          exit 1
        else
          echo "Stopped: $unit"
        fi
      '';
    };

  vpn-on = lib.makeOverridable mkOn { inherit services; };
  vpn-off = lib.makeOverridable mkOff { inherit services; };

  mkBundle =
    {
      services ? [ ],
      servicesOn ? services,
      servicesOff ? services,
    }:
    symlinkJoin {
      name = "vpn-scripts";
      paths = [
        (vpn-on.override { services = servicesOn; })
        (vpn-off.override { services = servicesOff; })
      ];
    };
in
{
  inherit vpn-on vpn-off;
  vpn-scripts = lib.makeOverridable mkBundle { inherit services; };
}
