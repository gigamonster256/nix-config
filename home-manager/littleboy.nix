{
  # You can import other home-manager modules here
  imports = [
    ./home.nix
  ];

   # Set your username
  home = {
    username = "caleb";
    homeDirectory = "/home/caleb";
  };

}