flake: {
  unify.nixos =
    { lib, ... }:
    {
      boot.loader.systemd-boot.configurationLimit = lib.mkDefault 20;
      system.autoUpgrade = {
        enable = lib.mkDefault true;
        flake = lib.mkDefault flake.config.meta.flake;
        # TODO: hmm this seems a little unsafe
        flags = [ "--accept-flake-config" ];
      };

      home-manager.backupFileExtension = lib.mkDefault "backup";
      # services.blueman.enable = lib.mkDefault config.hardware.bluetooth.enable;
      # TODO: fix this up
      networking.useNetworkd = true; # https://github.com/nix-community/nixos-facter-modules/issues/83
    };

  persistence.programs.nixos = {
    fwupd = {
      namespace = "services";
      directories = [
        "/var/cache/fwupd"
        "/var/lib/fwupd"
      ];
    };
  };
}
