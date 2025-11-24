{ inputs, ... }:
{
  unify.hosts.nixos.tinyca = {
    nixos =
      { lib, pkgs, ... }:
      {
        imports = [
          inputs.nixos-hardware.nixosModules.raspberry-pi-3
        ];

        services.openssh.enable = true;
        nixpkgs.hostPlatform = "aarch64-linux";

        users = {
          mutableUsers = false;
          users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3tGxUsgEJN/dwJ+QovVJd0yNg+YkJercIjGVJD+rvt caleb@chnorton-fw"
          ];
        };

        networking = {
          defaultGateway = {
            address = "172.16.15.1";
            interface = "enu1u1u1";
          };
          interfaces.enu1u1u1 = {
            ipv4.addresses = [
              {
                address = "172.16.15.20";
                prefixLength = 24;
              }
            ];
            ipv6.addresses = [
              {
                address = "2001:470:b8c5:400::20";
                prefixLength = 64;
              }
            ];
            useDHCP = false;
          };
        };

        # "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" creates a
        # disk with this label on first boot. Therefore, we need to keep it. It is the
        # only information from the installer image that we need to keep persistent
        fileSystems."/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
        };
        # save space by only including the rpi related dtbs (in theory)
        hardware.deviceTree.filter = "*-rpi-*.dtb";
        boot = {
          kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
          loader = {
            generic-extlinux-compatible.enable = lib.mkDefault true;
            grub.enable = lib.mkDefault false;
            systemd-boot.enable = lib.mkForce false;
          };
        };
        nix.settings = {
          experimental-features = lib.mkDefault "nix-command flakes";
          trusted-users = [
            "root"
            "@wheel"
          ];
        };

        # pi cant even eval itself without an oom killer
        system.autoUpgrade.enable = false;

        # use interpreterless initialization
        system.nixos-init.enable = true;
        # required for nixos-init
        system.etc.overlay.enable = true;
        services.userborn.enable = true; # or systemd.sysusers.enable

        system.stateVersion = "25.11";
      };
  };
}
