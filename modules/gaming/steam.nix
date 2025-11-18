{
  unify.modules.gaming.nixos = {
    programs.steam.enable = true;
    hardware.steam-hardware.enable = true;
    services.joycond.enable = true;
  };

  # TODO: somehow integrate with impermanence.programs.nixos option?
  unify.modules.impermanence.nixos =
    { lib, config, ... }:
    lib.mkIf config.programs.steam.enable {
      # steam is configured at the system level but stores data in the home directory
      home-manager.sharedModules = [
        {
          impermanence.directories = [
            ".local/share/Steam"
            ".local/share/applications" # save installed game entries - a little crufty
          ];
        }
      ];
    };
}
