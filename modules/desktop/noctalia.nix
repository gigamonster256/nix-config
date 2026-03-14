{ inputs, ... }:
{
  flake.modules.homeManager.default = {
    imports = [
      inputs.noctalia.homeModules.default
    ];
  };
  flake.modules.homeManager.noctalia =
    { lib, config, ... }:
    {
      programs.noctalia-shell = {
        enable = lib.mkDefault true;
        systemd.enable = config.programs.noctalia-shell.enable;
        settings.general.showChangelogOnStartup = false;
      };
    };

  persistence.programs.homeManager = {
    noctalia-shell = {
      directories = [
        ".cache/noctalia"
      ];
    };
  };
}
