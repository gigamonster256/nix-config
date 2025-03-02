{pkgs, ...}: {
  imports = [
    ./optional/waybar/default.nix
    ./optional/btop.nix
  ];

  home = {
    username = "caleb";
    homeDirectory = "/home/caleb";
  };

  home.packages = [
    pkgs.kitty
    pkgs.firefox
  ];

  programs.spicetify.enable = true;
}
