{
  # generic chnorton configuration
  imports = [
    ./global
    ./optional/linux.nix
  ];

  home = {
    username = "chnorton";
    homeDirectory = "/home/chnorton";
  };
}
