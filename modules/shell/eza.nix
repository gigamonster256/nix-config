{
  unify.home =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      programs.eza = {
        enable = lib.mkDefault true;
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
