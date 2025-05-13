{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkIf mkMerge;
  cfg = config.programs.eza;
in
mkMerge [
  {
    programs.eza = {
      colors = mkDefault "auto";
      icons = mkDefault "auto";
      enableZshIntegration = mkDefault config.programs.zsh.enable;
      git = mkDefault config.programs.git.enable;
      extraOptions = mkDefault [
        "--group-directories-first"
        "--header"
        "--no-quotes"
      ];
    };
  }
  (mkIf cfg.enable {
    home.sessionVariables.EZA_CONFIG_DIR = mkDefault "${config.xdg.configHome}/eza";

    xdg.configFile."eza/theme.yml" = mkDefault {
      source = "${pkgs.eza-themes.builtin}/share/eza/themes/catppuccin.yml";
    };
  })
]
