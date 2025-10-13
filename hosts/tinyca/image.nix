{ inputs, ... }:
{
  flake.images.tinyca =
    (inputs.self.nixosConfigurations.tinyca.extendModules {
      modules = [
        "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
      ];
    }).config.system.build.sdImage;
}
