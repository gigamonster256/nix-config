{
  flake.modules =
    let
      vid = "046d"; # logitech
      pid = "0a66"; # G533
    in
    {
      nixos.desktop =
        { lib, pkgs, ... }:
        {
          # grant access to plugdev group
          users.groups.plugdev = { };
          services.udev.packages = lib.singleton (
            pkgs.writeTextDir "etc/udev/rules.d/99-logitech-g533.rules" ''
              KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="${vid}", ATTRS{idProduct}=="${pid}", MODE="0660", GROUP="plugdev"
            ''
          );
        };

      homeManager.desktop =
        {
          lib,
          pkgs,
          ...
        }:
        let
          # TODO - optionize to add default sink name and fallback sink name
          # poll intervals as well and maybe even the vid/pid for the headset
          # but need to pass to nixos module as well for udev rules
          headsetMonitorScript = pkgs.writeShellApplication {
            name = "pipewire-headset-monitor";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.pipewire
              pkgs.wireplumber
              pkgs.headsetcontrol
              pkgs.jq
            ];
            text = ''
              HEADSET_SINK="G533"
              FALLBACK_SINK="Ryzen HD Audio Controller Analog Stereo"
              POLL_INTERVAL_OFF=5
              POLL_INTERVAL_ON=15
              LAST_STATE=""
              LAST_SINK_NAME=""

              is_connected() {
                [[ "$(headsetcontrol -d 0x${vid}:0x${pid} --connected 2>/dev/null)" == "true" ]]
              }

              find_sink_id() {
                local search="$1"
                pw-dump 2>/dev/null | jq -r --arg s "$search" '
                  .[]
                  | select(.type == "PipeWire:Interface:Node")
                  | select(.info.props."media.class" == "Audio/Sink")
                  | select(
                      (.info.props."node.description" // "" | ascii_downcase | contains($s | ascii_downcase))
                      or
                      (.info.props."node.name" // "" | ascii_downcase | contains($s | ascii_downcase))
                    )
                  | .id
                  ' | head -n1
              }

              get_default_sink_name() {
                wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null \
                  | grep -oP 'node\.name\s*=\s*"?\K[^"]+' \
                  | head -n1
              }

              find_sink_id_by_name() {
                local name="$1"
                pw-dump 2>/dev/null | jq -r --arg n "$name" '
                  .[]
                  | select(.type == "PipeWire:Interface:Node")
                  | select(.info.props."media.class" == "Audio/Sink")
                  | select(.info.props."node.name" == $n)
                  | .id
                  ' | head -n1
              }

              switch_to_sink() {
                local search="$1"
                local sink_id
                sink_id=$(find_sink_id "$search")
                if [[ -n "$sink_id" ]]; then
                  wpctl set-default "$sink_id" 2>/dev/null && echo "Default sink -> $search (id=$sink_id)"
                else
                  echo "ERROR: Sink '$search' not found"
                  return 1
                fi
              }

              echo "=== Starting headset monitor ==="

              while true; do
                if is_connected; then
                  if [[ "$LAST_STATE" != "connected" ]]; then
                    LAST_SINK_NAME=$(get_default_sink_name)
                    echo "Headset connected (previous sink=$LAST_SINK_NAME)"
                    switch_to_sink "$HEADSET_SINK"
                    LAST_STATE="connected"
                  fi
                  sleep "$POLL_INTERVAL_ON"
                else
                  if [[ "$LAST_STATE" != "disconnected" ]]; then
                    echo "Headset disconnected"
                    if [[ -n "$LAST_SINK_NAME" ]]; then
                      restore_id=$(find_sink_id_by_name "$LAST_SINK_NAME")
                      if [[ -n "$restore_id" ]] && wpctl set-default "$restore_id" 2>/dev/null; then
                        echo "Default sink -> $LAST_SINK_NAME (id=$restore_id)"
                      else
                        echo "Restoring last sink failed, falling back to default"
                        switch_to_sink "$FALLBACK_SINK"
                      fi
                    else
                      switch_to_sink "$FALLBACK_SINK"
                    fi
                    LAST_SINK_NAME=""
                    LAST_STATE="disconnected"
                  fi
                  sleep "$POLL_INTERVAL_OFF"
                fi
              done
            '';
          };
        in
        {
          systemd.user.services.pipewire-headset-monitor = {
            Unit = {
              Description = "PipeWire headset auto-switch monitor";
              After = [
                "pipewire.service"
                "wireplumber.service"
              ];
              Wants = [
                "pipewire.service"
                "wireplumber.service"
              ];
            };
            Service = {
              Type = "simple";
              ExecStart = lib.getExe headsetMonitorScript;
              Restart = "on-failure";
              RestartSec = 5;
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
          };
        };
    };
}
