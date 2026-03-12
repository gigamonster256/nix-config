flake: {
  unify.nixos =
    { lib, ... }:
    {
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

      # dont install documentation
      documentation = {
        doc.enable = false;
        nixos.enable = false;
      };

      # only ed25519 ssh host keys
      services.openssh.hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
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
