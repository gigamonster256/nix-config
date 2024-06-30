{pkgs, ...}: let
  btop-with-themes = pkgs.symlinkJoin {
    name = "btop-with-themes";
    paths = with pkgs; [
      btop
      btop-themes.catppuccin
    ];
  };
in {
  home.packages = [
    btop-with-themes
  ];
}
