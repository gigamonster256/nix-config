{ inputs, ... }:
{
  nixpkgs.overlays = [
    # bring in opencode dev and apply nixpkgs patches (bun version relaxation, etc...)
    (final: prev: {
      opencode =
        inputs.opencode.packages.${final.stdenv.hostPlatform.system}.opencode.overrideAttrs
          (old: {
            patches = (old.patches or [ ]) ++ prev.opencode.patches;
          });
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
