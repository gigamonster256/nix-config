{ inputs, ... }:
{
  flake.modules.nixos.facter =
    { lib, config, ... }:
    {
      imports = [
        inputs.nixos-facter-modules.nixosModules.facter
      ];

      facter.reportPath = lib.mkDefault ../../hosts/${config.networking.hostName}/facter.json;
    };
}
