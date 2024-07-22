# for some reason the derivation for home-manager-fonts has these packages
# in a different order when building home-manager as a nix-darwin module vs
# standalone when these packages are placed in ../chnorton-mbp.nix
# pulling this config option out into a separate file makes sure that the hash of the
# home-manager-fonts derivation is the same in both cases (the fonts derivation relies on config.home.packages)
# for whatever reason, this refactor means that the config.home.packages final list is in the same order
# (some sort of merging difference between the two ways of building?)
{pkgs, ...}: {
  home.packages = with pkgs; [
    raycast
    iterm2
    pinentry_mac
    trilium-desktop
    # code editing
    vscode
    nil
  ];
}
