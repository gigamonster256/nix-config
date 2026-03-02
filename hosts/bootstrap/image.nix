{ inputs, ... }:
{
  flake.images.bootstrap =
    (inputs.self.nixosConfigurations.bootstrap.extendModules {
      modules = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
        # some isoImage modules set boot.postBootCommands which does not work with nixos-init
        # FIXME: this is untested - the postBootCommands look to be optional
        # but i havent actually used this installer since this override was added
        # may be better to mkForce system.nixos-init.enable to false
        (
          { lib, ... }:
          {
            boot.postBootCommands = lib.mkForce "";
          }
        )
      ];
    }).config.system.build.isoImage;
}
