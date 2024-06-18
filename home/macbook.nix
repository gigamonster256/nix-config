{pkgs, ...}: {
  imports = [
    ./global
  ];

  home = {
    username = "caleb";
    homeDirectory = "/Users/caleb";
  };

  home.packages = with pkgs; [
    spotify
    iterm2
    pinentry_mac
    trilium-desktop
    # code editing
    vscode
    nil
  ];
}
