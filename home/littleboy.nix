{pkgs, ...}: {
  home = {
    username = "caleb";
    homeDirectory = "/home/caleb";
  };

  home.packages = [
    pkgs.kitty
    pkgs.firefox
  ];

  programs.spicetify.enable = true;
  programs.waybar.enable = true;
  programs.ghostty.enable = true;

  # TODO: refactor this
  programs.btop.enable = true;
  home.file."./.config/btop/themes" = {
    source = "${pkgs.btop-themes.catppuccin}/share/btop/themes";
  };
}
