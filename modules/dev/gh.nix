{
  flake.modules.homeManager.base =
    { lib, config, ... }:
    let
      gitcfg = config.programs.git;
      ghcfg = config.programs.gh;
    in
    {
      programs.gh = {
        enable = lib.mkDefault gitcfg.enable;
        settings = {
          git_protocol = lib.mkDefault "ssh";
        };
        hosts = {
          "github.com" = {
            git_protocol = lib.mkDefault ghcfg.settings.git_protocol;
            user = lib.mkDefault "gigamonster256";
          };
        };
      };

      home.shellAliases = lib.mkIf ghcfg.enable {
        gpl = "gh pr list";
        gpm = "gh pr merge";
      };
    };
}
