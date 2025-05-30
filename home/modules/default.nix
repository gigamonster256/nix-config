{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault optionalAttrs;
in
{
  # You can import other home-manager modules here
  imports = [
    ./zsh
    ./waybar
    ./nh.nix
    ./nix.nix
    ./ghostty.nix
    ./spicetify.nix
    ./firefox.nix
    ./macos-trampolines
    ./git.nix
    ./jujutsu.nix
    ./hypr
    ./btop.nix
    ./eza.nix
    ./cursor.nix
  ];

  fonts.fontconfig.enable = true;

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        global.hide_env_diff = true;
        global.load_dotenv = true;
      };
    };
    git.enable = true;
    btop.enable = true;
    eza.enable = true;
    jujutsu.enable = true;
    zsh.enable = true;
    nh.enable = true;
    nix-index-database.comma.enable = true;
    nix-index.enable = true;
  };

  home = {
    packages = builtins.attrValues (
      {
        inherit (pkgs)
          neovim
          devenv
          magic-wormhole # TODO try out the rust or go version?
          # hyperbeam # pipes via hyperswarm - alternative to magic-wormhole
          ;
      }
      // (optionalAttrs pkgs.stdenv.isLinux {
        inherit (pkgs)
          file
          usbutils
          ;
      })
    );
    sessionVariables.EDITOR = "nvim";
    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = mkDefault "23.11";
  };

  # typos
  home.shellAliases = {
    nvom = "nvim";
    nivm = "nvim";
    sl = "ls";
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
