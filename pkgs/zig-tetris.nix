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
      pname = "zig-tetris";
      version = "0.1.0";

      src = fetchFromGitHub {
        owner = "andrewrk";
        repo = "tetris";
        rev = "9594457bb2468044863adf5f3e3ff8d11505310e";
        hash = "sha256-0kvO0TPTZOgjrEmWaK9lWa+SspjnPyPFPcm33QFJzU8=";
      };

      nativeBuildInputs = [
        zig.hook
      ];

      buildInputs = [
        glfw
        libepoxy
      ];

      meta = {
        description = "Simple tetris clone written in zig programming language";
        homepage = "https://github.com/andrewrk/tetris";
        license = lib.licenses.mit;
        mainProgram = "tetris";
        platforms = lib.foldl' lib.intersectLists lib.platforms.all (
          map (p: p.meta.platforms or [ ]) finalAttrs.buildInputs
        ); # hmm this style seems interesting as a default
      };
    });
}
