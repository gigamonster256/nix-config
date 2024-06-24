{
  pkgs,
  inputs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in {
  imports = [inputs.spicetify-nix.homeManagerModules.default];

  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.dribbblish;
    colorScheme = "catppuccin-mocha";

    enabledExtensions = with spicePkgs.extensions; [
      fullAppDisplay
      shuffle
    ];
  };
}
