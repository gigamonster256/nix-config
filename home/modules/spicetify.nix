{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkIf mkMerge;
  cfg = config.programs.spicetify;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
mkMerge [
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
  (mkIf cfg.enable {
    home.packages = mkIf pkgs.stdenv.isLinux [ pkgs.playerctl ];
    impermanence.directories = [ ".config/spotify" ];
  })
]
