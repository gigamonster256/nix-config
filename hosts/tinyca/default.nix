{ inputs, ... }:
{
  unify.hosts.nixos.tinyca = {
    nixos = {
      imports = [
        inputs.nixos-hardware.nixosModules.raspberry-pi-3
      ];

      services.openssh.enable = true;
      nixpkgs.hostPlatform = "aarch64-linux";

      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3tGxUsgEJN/dwJ+QovVJd0yNg+YkJercIjGVJD+rvt caleb@chnorton-fw"
      ];

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

      system.stateVersion = "25.11";
    };
  };
}
