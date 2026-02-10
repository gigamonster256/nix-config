{ inputs, ... }:
{
  unify.home = {
    imports = [
      inputs.noctalia.homeModules.default
    ];
  };
  unify.modules.noctalia.home =
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
