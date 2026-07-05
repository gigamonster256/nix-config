{
  packages.tetris =
    {
      lib,
      stdenv,
      fetchFromGitHub,
      zig,
      glfw,
      libepoxy,
    }:
    stdenv.mkDerivation (finalAttrs: {
      name = "zig-tetris";

      src = fetchFromGitHub {
        owner = "andrewrk";
        repo = "tetris";
        rev = "b587b2676956045777f512a1482ed93701a04cfd";
        hash = "sha256-6USLgLkc9WMMwbm0OzxSxiYnKI+dx9a0hJil/pQOO10=";
      };

      nativeBuildInputs = [
        zig
      ];

      buildInputs = [
        glfw
        libepoxy
      ];

      meta = {
        description = "Simple tetris clone written in zig programming language";
        homepage = "https://github.com/andrewrk/tetris";
        license = lib.licenses.mit;
        maintainers = [ lib.maintainers.gigamonster256 ];
        mainProgram = "tetris";
        platforms = lib.foldl' lib.intersectLists lib.platforms.all (
          map (p: p.meta.platforms or [ ]) finalAttrs.buildInputs
        ); # hmm this style seems interesting as a default
      };
    });
}
