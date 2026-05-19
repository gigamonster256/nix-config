flake: {
  configurations.nixos.bootstrap =
    { lib, ... }:
    {
      system.autoUpgrade.enable = lib.mkForce false;
      # allow this device to be discovered as bootstrap.local
      services.avahi = {
        enable = true;
        publish = {
          enable = true;
          addresses = true;
        };
      };
      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keys = flake.config.meta.owner.sshKeys;

      # smaller closure
      documentation.enable = false;
      # use interpreterless initialization
      system.nixos-init.enable = true;
      # required for nixos-init
      system.etc.overlay.enable = true;
      services.userborn.enable = true; # or systemd.sysusers.enable
      programs.nano.enable = false;
      environment.defaultPackages = [ ];
      nix = {
        registry = lib.mkForce { };
        nixPath = lib.mkForce [ ];
      };

      # dummy value to satisfy base nixos configuration assertions
      # this is designed to be run as a live usb or netboot image and doesnt need a real root device
      fileSystems."/".device = "/dev/sda";
      fileSystems."/".fsType = "nodev";

      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "26.05";
    };
}
