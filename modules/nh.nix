{ lib, config, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      nh-unwrapped = prev.nh-unwrapped.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (final.fetchpatch2 {
            url = "https://patch-diff.githubusercontent.com/raw/nix-community/nh/pull/592.patch?full_index=1";
            hash = "sha256-McF1XObLlVdW5pQ1LhKz1HLrgteFkW4fKiKm0LgeH4I=";
          })
        ];
      });
    })
  ];

  unify.home = {
    programs.nh = {
      enable = lib.mkDefault true;
      flake = lib.mkDefault config.meta.flake;
    };
  };
}
