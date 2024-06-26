{
  imports = [
    ./global
    ./macos # see file for details

    ./optional/spotify.nix
    ./optional/btop.nix
  ];

  home = {
    username = "caleb";
    homeDirectory = "/Users/caleb";
  };
}
