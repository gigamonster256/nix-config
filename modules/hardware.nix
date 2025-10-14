{ inputs, ... }:
{
  unify.nixos = {
    imports = [
      inputs.disko.nixosModules.disko
      inputs.nixos-facter-modules.nixosModules.facter
    ];
  };
}
