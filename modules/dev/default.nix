{
  flake.modules.homeManager.dev = {
    # folder for persistent projects
    persistence.directories = [ "git" ];
  };

  flake.modules.nixos.dev = {
    # not sure where to put these
    services.proxy-dev.hosts = {
      portal = 4000;
      spark = 8080;
      homepage = 3000;
    };
  };
}
