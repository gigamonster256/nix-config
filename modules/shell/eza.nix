{
  unify.home =
    {
      pkgs,
      config,
      ...
    }:
    {
      programs.eza = {
        colors = "auto";
        icons = "auto";
        enableZshIntegration = config.programs.zsh.enable;
        git = config.programs.git.enable;
        extraOptions = [
          "--group-directories-first"
          "--header"
          "--no-quotes"
        ];
      };
    };
}
