{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
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
  home.packages = mkIf (config.programs.spicetify.enable && pkgs.stdenv.isLinux) [ pkgs.playerctl ];
}
