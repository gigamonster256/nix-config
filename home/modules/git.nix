{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault;
  gitcfg = config.programs.git;
  ghcfg = config.programs.gh;
in
{
  sops.secrets.gh_token = {
    sopsFile = ./secrets.yaml;
  };
  programs.git = {
    userName = mkDefault "Caleb Norton";
    userEmail = mkDefault "n0603919@outlook.com";
    aliases = {
      exec = mkDefault "!exec ";
    };
  };
  programs.gh = {
    enable = mkDefault gitcfg.enable;
    settings = {
      git_protocol = mkDefault "ssh";
    };
    hosts = {
      "github.com" = {
        git_protocol = mkDefault ghcfg.settings.git_protocol;
        user = mkDefault "gigamonster256";
      };
    };
  };

  home.shellAliases = {
    gh = "GH_TOKEN=`cat ${config.sops.secrets.gh_token.path}` gh";
  };
}
