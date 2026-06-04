{
  flake.modules.homeManager.dev =
    {
      lib,
      pkgs,
      ...
    }:
    {
      programs.devenv.enable = true;
      programs.zsh.initContent = lib.mkOrder 600 ''
        eval "$(${lib.getExe pkgs.devenv} hook zsh)"
      '';
    };

  persistence.wrappers.homeManager = [
    "devenv"
  ];

  persistence.programs.homeManager = {
    devenv = {
      directories = [ ".local/share/devenv" ];
    };
  };
}
