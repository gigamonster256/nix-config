{ inputs, moduleWithSystem, ... }:
{
  unify.modules.style.home = moduleWithSystem (
    { system, ... }:
    { lib, config, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${system};
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.default ];
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
      # replace spotify package with spiced spotify
      programs.spotify.package = lib.mkDefault config.programs.spicetify.spicedSpotify;
    }
  );
}
