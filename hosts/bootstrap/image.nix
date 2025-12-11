{ inputs, ... }:
{
  flake.images.bootstrap =
    (inputs.self.nixosConfigurations.bootstrap.extendModules {
      modules = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
      ];
    }).config.system.build.isoImage;
}
