{
  flake.modules.homeManager.dev = {
    programs.devenv.enable = true;
  };

  persistence.programs.homeManager = {
    devenv = {
      directories = [ ".local/share/devenv" ];
    };
  };
}
