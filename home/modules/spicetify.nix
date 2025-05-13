{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
  programs.spicetify = {
    theme = mkDefault spicePkgs.themes.dribbblish;
    colorScheme = mkDefault "catppuccin-mocha";
    enabledExtensions = mkDefault (
      builtins.attrValues {
        inherit (spicePkgs.extensions)
          fullAppDisplay
          shuffle
          ;
      }
    );
  };
}
