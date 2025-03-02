{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [inputs.spicetify-nix.homeManagerModules.default];

  programs.spicetify = let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  in {
    theme = lib.mkDefault spicePkgs.themes.dribbblish;
    colorScheme = lib.mkDefault "catppuccin-mocha";
    enabledExtensions = lib.mkDefault (builtins.attrValues {
      inherit
        (spicePkgs.extensions)
        fullAppDisplay
        shuffle
        ;
    });
  };
}
