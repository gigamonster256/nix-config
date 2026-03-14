{ inputs, ... }:
{
  # making minimal installs
  flake.modules.nixos.minimal = {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/profiles/headless.nix"
      "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
    ];

    # only add strictly necessary modules
    boot.initrd.includeDefaultModules = false;
    #   boot.initrd.kernelModules = [ "ext4" ... ];
    disabledModules = [
      "${inputs.nixpkgs}/nixos/modules/profiles/all-hardware.nix"
      "${inputs.nixpkgs}/nixos/modules/profiles/base.nix"
    ];
  };
}
