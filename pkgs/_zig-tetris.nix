{
  lib,
  stdenv,
  fetchFromGitHub,
  zig_0_14,
  glfw,
  libepoxy,
}:
let
  zig = zig_0_14;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zig-tetris";
  version = "master";

  src = fetchFromGitHub {
    owner = "andrewrk";
    repo = "tetris";
    rev = finalAttrs.version;
    hash = "sha256-M6Y9arEMbecXvzyvPkt/qP1sNJcVM1Avkd/lnmRvadY=";
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
})
