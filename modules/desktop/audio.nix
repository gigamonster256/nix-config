{
  # millisecond app is helpful for diagnosis of common audio issues
  unify.modules.desktop.nixos =
    { pkgs, ... }:
    {
      # https://wiki.linuxaudio.org/wiki/system_configuration#quality_of_service_interface
      services.udev.packages = [
        (pkgs.writeTextDir "etc/udev/rules.d/99-cpu-dma-latency.rules" ''
          DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
        '')
      ];
      # https://wiki.linuxaudio.org/wiki/system_configuration#limitsconfaudioconf
      security.pam.loginLimits = [
        {
          domain = "@audio";
          type = "-";
          item = "rtprio";
          value = "90";
        }
        {
          domain = "@audio";
          type = "-";
          item = "memlock";
          value = "unlimited";
        }
      ];
    };
}
