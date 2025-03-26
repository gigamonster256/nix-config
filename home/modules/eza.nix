{
  pkgs,
  lib,
  config,
  ...
}: {
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

  home.sessionVariables.EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";

  xdg.configFile."eza/theme.yml" = lib.mkIf config.programs.eza.enable {
    source = "${pkgs.eza-themes.builtin}/share/eza/themes/catppuccin.yml";
  };
}
