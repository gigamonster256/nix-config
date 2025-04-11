{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [./nix.nix];

  fonts.packages = [
    (pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];})
    # monaspace 1.200 has nerd fonts built in
    pkgs.unstable.monaspace
  ];
}
