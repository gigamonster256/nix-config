{ inputs, ... }:
{
  unify.modules.facter.nixos =
    { lib, hostConfig, ... }:
    {
      imports = [
        inputs.nixos-facter-modules.nixosModules.facter
      ];

      facter.reportPath = lib.mkDefault ../../hosts/${hostConfig.name}/facter.json;
    };
}
