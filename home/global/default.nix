# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    ./zsh
    ./waybar
    ./nh.nix
    ./nix.nix
    ./ghostty.nix
    ./spicetify.nix
  ];

  fonts.fontconfig.enable = true;

  programs = {
    git.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        global.hide_env_diff = true;
        global.load_dotenv = true;
      };
    };
  };

  home.packages = builtins.attrValues {
    inherit
      (pkgs)
      neovim
      devenv
      ;
  };

  home.sessionVariables.EDITOR = "nvim";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
