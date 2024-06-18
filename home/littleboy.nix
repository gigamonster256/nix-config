{pkgs, ...}: {
  imports = [
    ./global
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
