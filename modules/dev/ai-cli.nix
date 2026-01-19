{ inputs, ... }:
{
  nixpkgs.overlays = [
    # bring in opencode dev
    (final: _prev: {
      inherit (inputs.opencode.packages.${final.stdenv.hostPlatform.system}) opencode;
    })
  ];

  unify.modules.dev.home =
    { lib, ... }:
    {
      programs.opencode.enable = lib.mkDefault true;
      # programs.gemini-cli.enable = lib.mkDefault true;
    };

  persistence.programs.homeManager = {
    opencode = {
      directories = [ ".local/share/opencode" ];
    };
    gemini-cli = {
      directories = [ ".gemini" ];
    };
  };
}
