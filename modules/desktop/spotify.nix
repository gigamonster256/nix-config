{
  nixpkgs.allowedUnfreePackages = [
    "spotify"
  ];

  persistence.wrappers.homeManager = [
    "spotify"
  ];

  # FIXME: have auto-wrapping functionality?
  # createOption = true/false flag which creates the persistence.wrappers.homeManager entry?
  # would this need to then take the packageName and namespace options as well?
  persistence.programs.homeManager = {
    spotify = {
      directories = [ ".config/spotify" ];
      # createOption = true;
    };
  };

  unify.home =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    lib.mkIf config.programs.spotify.enable {
      home.packages = lib.optional pkgs.stdenv.isLinux pkgs.playerctl;
    };
}
