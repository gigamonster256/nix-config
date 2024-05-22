# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (pkgs) stdenv;
in {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # Set your username
  home = {
    username = "caleb";
    homeDirectory =
      if stdenv.isLinux
      then "/home/caleb"
      else if stdenv.isDarwin
      then "/Users/caleb"
      else assert false; "Unsupported system";
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      warn-dirty = false;
    };
  };

  fonts.fontconfig.enable = true;

  # Add stuff for your user as you see fit:
  home.packages = with pkgs; let
    pinentry-app =
      if stdenv.isLinux
      then pinentry-curses
      else pinentry_mac;
    term =
      if stdenv.isLinux
      then kitty
      else iterm2;
  in
    [
      spotify
      font-awesome
      hack-font
      pinentry-app
      term
      nil
    ]
    ++ lib.optionals stdenv.isLinux [
      # Add linux-only packages here
    ]
    ++ lib.optionals stdenv.isDarwin [
      # Add darwin-only packages here
      trilium-desktop
    ];

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    oh-my-zsh = {
      enable = true;
      plugins = ["git"];
      theme = "robbyrussell";
    };
  };

  programs.neovim = {
    enable = true;
  };
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
