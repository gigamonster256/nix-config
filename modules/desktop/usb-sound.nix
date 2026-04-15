{
  flake.modules.nixos.desktop =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # TODO: non-pipewire+systemd?
      playWavAsUser =
        name: wav:
        pkgs.writeShellApplication {
          name = "play-${name}";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.gawk
            pkgs.systemd
          ];
          text = ''
            uid=$(id -u)
            if [ "$uid" = "0" ]; then
              user=$(who | awk 'NR==1{print $1}')
              if [ -n "$user" ]; then
                uid=$(id -u "$user")
                # need to use full path to pw-cat here since systemd-run doesn't have the PATH from the wrapper
                systemd-run --user --machine="$user@.host" --pipe \
                  ${lib.getExe' pkgs.pipewire "pw-cat"} --volume 1 --playback ${wav}
              fi
            else
              ${lib.getExe' pkgs.pipewire "pw-cat"} --volume 1 --playback ${wav}
            fi
          '';
        };
      connectSound = playWavAsUser "connect" pkgs.usb-mark-sound.wav;
      disconnectSound = playWavAsUser "disconnect" pkgs.usb-no-sound.wav;
      chargingConnectSound = playWavAsUser "charging-connect" pkgs.usb-halo-charge-sound.wav;
      chargingDisconnectSound = playWavAsUser "charging-disconnect" pkgs.usb-halo-deplete-sound.wav;

      # plug in goes through multiple states with ENV{POWER_SUPPLY_ONLINE}=="1" for PD negotiation
      # so we need to debounce
      debounceTime = 5; # seconds
      debounceScript =
        script:
        pkgs.writeShellScript "debounce-${script.name}" ''
          LOCKFILE="/tmp/debounce-${script.name}.lock"
          if [ -f "$LOCKFILE" ] && [ $(($(date +%s) - $(cat "$LOCKFILE"))) -lt ${toString debounceTime} ]; then
              exit 0
          fi
          date +%s > "$LOCKFILE"
          exec ${lib.getExe script}
        '';
    in
    {
      services.udev.packages = [
        (pkgs.writeTextDir "etc/udev/rules.d/99-usb-sounds.rules" ''
          ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="${lib.getExe connectSound}"
          ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="${lib.getExe disconnectSound}"

          ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="ACAD", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${debounceScript chargingConnectSound}"
          ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="ACAD", ENV{POWER_SUPPLY_ONLINE}=="0", RUN+="${lib.getExe chargingDisconnectSound}"
        '')
      ];
    };
}
