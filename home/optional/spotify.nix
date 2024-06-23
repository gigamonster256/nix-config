{ pkgs, inputs, ... }:
let
  spicePkgs = inputs.spicetify-nix.packages.${pkgs.system}.default;
in
{
  # # allow spotify to be installed if you don't have unfree enabled already
  # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  #   "spotify"
  # ];

  # import the flake's module for your system
  imports = [ inputs.spicetify-nix.homeManagerModule ];

  home.packages = with pkgs; [
    spotify
  ];

  # configure spicetify :)
  programs.spicetify =
    {
      enable = true;
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";

      enabledExtensions = with spicePkgs.extensions; [
        fullAppDisplay
        shuffle # shuffle+ (special characters are sanitized out of ext names)
        # hidePodcasts
      ];
    };
}