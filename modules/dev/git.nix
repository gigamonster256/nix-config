{ config, ... }:
{
  unify.modules.dev.home =
    { lib, pkgs, ... }:
    {
      programs.git = {
        enable = lib.mkDefault true;
        settings = {
          user = {
            name = lib.mkDefault config.meta.owner.name;
            email = lib.mkDefault config.meta.owner.email;
          };
          alias = {
            exec = lib.mkDefault "!exec ";
          };
          init.defaultBranch = "master";
          diff.external = lib.mkDefault (lib.getExe pkgs.difftastic);
        };
      };
    };
}
