{pkgs, ...}: {
  imports = [
    ./global

    ./optional/spotify.nix
    ./optional/btop.nix
  ];

  home = {
    username = "caleb";
    homeDirectory = "/home/caleb";
  };

  home.packages = with pkgs; [
    kitty
    firefox
  ];
}
