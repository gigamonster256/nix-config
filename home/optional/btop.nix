{pkgs, ...}: {
  home.packages = with pkgs; [
    btop
  ];

  home.file."./.config/btop/themes" = {
    source = "${pkgs.btop-themes.catppuccin}/share/btop/themes";
  };
}
