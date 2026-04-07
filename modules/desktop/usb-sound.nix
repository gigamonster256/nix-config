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
      connectSound = playWavAsUser "connect" pkgs.usb-connect-sound.wav;
      disconnectSound = playWavAsUser "disconnect" pkgs.usb-disconnect-sound.wav;
    in
    {
      services.udev.packages = [
        (pkgs.writeTextDir "etc/udev/rules.d/99-usb-sounds.rules" ''
          ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="${lib.getExe connectSound}"
          ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="${lib.getExe disconnectSound}"
        '')
      ];
    };
}
