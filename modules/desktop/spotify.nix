{ inputs, ... }:
{
  unify.home = {
    imports = [ inputs.self.modules.homeManager.spotify ];
  };

  unify.modules.spotify.home =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.programs.spotify = {
        enable = lib.mkEnableOption "spotify";
        package = lib.mkPackageOption pkgs "spotify" { };
      };

      config = lib.mkIf config.programs.spotify.enable {
        home.packages = [
          config.programs.spotify.package
        ]
        ++ lib.optional pkgs.stdenv.isLinux pkgs.playerctl;
        # TODO: make this only if impermanence is imported/enabled - currently not suitable for external use
        impermanence.directories = [ ".config/spotify" ];
      };
    };
}
