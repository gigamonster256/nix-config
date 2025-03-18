{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [./nix.nix];

  fonts.packages = [
    (pkgs.nerdfonts.override {fonts = ["JetBrainsMono" "Monaspace"];})
  ];
}
