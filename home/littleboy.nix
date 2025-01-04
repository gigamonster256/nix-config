{pkgs, ...}: {
  imports = [
    ./global

    ./optional/waybar/default.nix
    ./optional/spotify.nix
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
}
