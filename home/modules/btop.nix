{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.btop = {
    settings = {
      color_theme = lib.mkDefault "${config.xdg.configHome}/btop/themes/catppuccin_mocha.theme";
    };
  };

  xdg.configFile."btop/themes" = lib.mkIf config.programs.btop.enable {
    source = "${pkgs.btop-themes.catppuccin}/share/btop/themes";
  };
}
