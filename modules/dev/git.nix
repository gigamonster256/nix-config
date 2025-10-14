{ config, lib, ... }:
{
  flake.modules.homeManager.base = {
    programs.git = {
      settings = {
        user = {
          name = lib.mkDefault config.meta.owner.name;
          email = lib.mkDefault config.meta.owner.email;
        };
        alias = {
          exec = lib.mkDefault "!exec ";
        };
        init.defaultBranch = "master";
      };
    };
  };
}
