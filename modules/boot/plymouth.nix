{
  flake.modules.nixos.plymouth = {
    boot = {
      plymouth.enable = true;
      consoleLogLevel = 3;
      kernelParams = [
        "quiet"
        "intremap=on"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
      ];
    };
  };
}
