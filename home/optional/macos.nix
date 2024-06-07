{pkgs, ...}: {
  home.packages = with pkgs; [
    spotify
    iterm2
    pinentry_mac
    trilium-desktop
  ];
}
