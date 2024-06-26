{pkgs, ...}: {
  home.packages = with pkgs; [
    btop
    btop-themes.catppuccin
  ];
}
