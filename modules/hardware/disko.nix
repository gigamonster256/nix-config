{ inputs, ... }:
{
  imports = [ inputs.disko.flakeModules.default ];
  flake.modules.nixos.disko =
    { lib, name, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      # kinda hacky since reading from config.networking.hostName causes infinite recursion
      # uses optionalAttrs since mkIf seems to not be lazy and tries to access the disko configuration even when it shouldn't
      # disko = lib.mkIf (inputs.self.diskoConfigurations ? ${name}) (lib.mkDefault inputs.self.diskoConfigurations.${name}.disko);
      # config = lib.optionalAttrs (inputs.self.diskoConfigurations ? ${config.networking.hostName}) {
      #   disko = lib.mkDefault inputs.self.diskoConfigurations.${config.networking.hostName}.disko;
      # };
      config = lib.optionalAttrs (inputs.self.diskoConfigurations ? ${name}) {
        disko = lib.mkDefault inputs.self.diskoConfigurations.${name}.disko;
      };
    };
}
