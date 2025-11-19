{
  packages.sowon =
    {
      lib,
      stdenv,
      SDL2,
      pkg-config,
      fetchFromGitHub,
    }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "sowon";
      version = "0.1.0";

      src = fetchFromGitHub {
        owner = "tsoding";
        repo = "sowon";
        rev = "4631d354cfb4c364b2c66e61f6b09166b8055fa3";
        hash = "sha256-moJqsYCyc+rzC2Zw4uGzE9PheHcrGU9p8d8xoG4oy1o=";
      };

      nativeBuildInputs = [
        pkg-config
      ];

      buildInputs = [
        SDL2
      ];

      # dont build or install the rgfw version
      postPatch = ''
        sed -i 's/all: Makefile sowon sowon_rgfw man/all: Makefile sowon man/' Makefile
        sed -i '\|\$(INSTALL) -C \./sowon_rgfw|d' Makefile
      '';

      makeFlags = [ "PREFIX=$(out)" ];

      meta = {
        description = "Starting Soon Timer for Tsoding Streams";
        homepage = "https://github.com/tsoding/sowon";
        license = lib.licenses.mit;
        mainProgram = "sowon";
        platforms = lib.foldl' lib.intersectLists lib.platforms.all (
          map (p: p.meta.platforms or [ ]) finalAttrs.buildInputs
        ); # hmm this style seems interesting as a default
      };
    });
}
