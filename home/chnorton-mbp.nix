{
  imports = [
    ./global
    ./macos # see file for details
    
    ./optional/spotify.nix
  ];

  home = {
    username = "caleb";
    homeDirectory = "/Users/caleb";
  };
}
