{
  moduleWithSystem,
  inputs,
  lib,
  ...
}:
lib.mkMerge [
  {
    unify.modules.style.home = moduleWithSystem (
      { system, ... }:
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${system};
      in
      {
        programs.spicetify = {
          theme = lib.mkDefault spicePkgs.themes.dribbblish;
          colorScheme = lib.mkDefault "catppuccin-mocha";
          enabledExtensions = lib.mkDefault (
            builtins.attrValues {
              inherit (spicePkgs.extensions)
                fullAppDisplay
                shuffle
                ;
            }
          );
        };
      }

    );
  }
  {
    unify.modules.style.home =
      { config, pkgs, ... }:
      {
        imports = [ inputs.spicetify-nix.homeManagerModules.default ];
        config = (
          lib.mkIf config.programs.spicetify.enable {
            home.packages = lib.mkIf pkgs.stdenv.isLinux [ pkgs.playerctl ];
            impermanence.directories = [ ".config/spotify" ];
          }
        );
      };
  }
]
