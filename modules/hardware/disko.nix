{ inputs, ... }:
{
  unify.modules.disko.nixos =
    { lib, hostConfig, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      disko = lib.mkDefault inputs.self.diskoConfigurations.${hostConfig.name}.disko;
    };
}
