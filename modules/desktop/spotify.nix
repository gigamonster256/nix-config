{
  nixpkgs.allowedUnfreePackages = [
    "spotify"
  ];
  
  home-manager.extraPrograms = [
    "spotify"
  ];

  impermanence.programs.home = {
    spotify = {
      directories = [ ".config/spotify" ];
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
