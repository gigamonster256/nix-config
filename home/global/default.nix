# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  lib,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    ./zsh
    ./nvim
    ./nh.nix
    ./nix.nix
  ];

  fonts.fontconfig.enable = true;

  programs = {
    git.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
