{ config, lib, ... }:
{
  flake.modules.homeManager.base = {
    programs.git = {
      userName = lib.mkDefault config.meta.owner.name;
      userEmail = lib.mkDefault config.meta.owner.email;
      aliases = {
        exec = lib.mkDefault "!exec ";
      };
      extraConfig = {
        init.defaultBranch = "master";
      };
    };
  };
}
