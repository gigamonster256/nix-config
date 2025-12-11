{ inputs, ... }:
{
  imports = [ inputs.disko.flakeModules.default ];
  unify.modules.disko.nixos =
    { lib, hostConfig, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      config = lib.optionalAttrs (inputs.self.diskoConfigurations ? ${hostConfig.name}) {
        disko = lib.mkDefault inputs.self.diskoConfigurations.${hostConfig.name}.disko;
      };
    };
}
