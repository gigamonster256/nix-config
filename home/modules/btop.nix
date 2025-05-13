{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  cfg = config.programs.btop;
in
{
  programs.btop = {
    settings = {
      color_theme = mkDefault "${config.xdg.configHome}/btop/themes/catppuccin_mocha.theme";
    };
  };

  xdg.configFile."btop/themes" = mkIf cfg.enable {
    source = "${pkgs.btop-themes.catppuccin}/share/btop/themes";
  };
}
