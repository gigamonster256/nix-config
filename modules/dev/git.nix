{ config, ... }:
{
  flake.modules.homeManager.dev =
    { lib, pkgs, ... }:
    {
      programs.git = {
        enable = lib.mkDefault true;
        signing.format = lib.mkDefault "openpgp";
        ignores = [
          # nix dev things
          ".direnv/"
          "result"
          "result-*"
          # .vscode settings
          ".vscode/"
        ];
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
