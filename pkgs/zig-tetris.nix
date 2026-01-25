{
  packages.tetris =
    {
      lib,
      stdenv,
      fetchFromGitHub,
      fetchFromGitLab,
      zig,
      glfw,
      libdecor,
      libepoxy,
      libGL,
      libX11,
    }:
    let
      libdecorPatched = libdecor.overrideAttrs (
        finalAttrs: prevAttrs: {
          version = "0.2.5";
          src = fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "libdecor";
            repo = "libdecor";
            tag = finalAttrs.version;
            hash = "sha256-sUktv/k+4IdJ55uH3F6z8XqaAOTic6miuyZ9U+NhtQQ=";
          };
          patches = (prevAttrs.patches or [ ]) ++ [
            ./libdecor.patch
          ];
        }
      );
      # window keeps shrinking
      # https://github.com/hyprwm/Hyprland/discussions/12200
      # https://gitlab.freedesktop.org/libdecor/libdecor/-/issues/80
      # even with libdecor 0.2.5, the size is still wrong
      # https://github.com/hyprwm/Hyprland/discussions/12200#discussioncomment-15133605
      # https://gitlab.freedesktop.org/libdecor/libdecor/-/issues/80#note_3221028
      # https://github.com/glfw/glfw/issues/2789
      glfwPatched =
        (glfw.override {
          libdecor = libdecorPatched;
        }).overrideAttrs
          (prevAttrs: {
            patches = (prevAttrs.patches or [ ]) ++ [
              ./glfw.patch
            ];
          });

      x11Support = false;
      _libepoxyNoX11 =
        (libepoxy.override {
          inherit x11Support;
        }).overrideAttrs
          (
            finalAttrs: _prevAttrs: {
              # x11Support is too integrated into macos vs linux
              propagatedBuildInputs =
                lib.optionals (!stdenv.hostPlatform.isDarwin) [
                  libGL
                ]
                ++ lib.optionals x11Support [
                  libX11
                ];
              mesonFlags = [
                "-Degl=${lib.boolToYesNo (!stdenv.hostPlatform.isDarwin)}"
                "-Dglx=${lib.boolToYesNo x11Support}"
                "-Dtests=${lib.boolToString finalAttrs.finalPackage.doCheck}"
                "-Dx11=${lib.boolToString x11Support}"
              ];
              env.NIX_CFLAGS_COMPILE = lib.optionalString (
                !stdenv.hostPlatform.isDarwin
              ) ''-DLIBGL_PATH="${lib.getLib libGL}/lib"'';
            }
          );

      glfwNoX11 = glfwPatched.overrideAttrs (
        _finalAttrs: prevAttrs: {
          cmakeFlags = prevAttrs.cmakeFlags ++ [
            (lib.cmakeBool "GLFW_BUILD_X11" false)
          ];
          # filter "libx*" buildInputs except libxkeyboard
          buildInputs = lib.filter (
            p: !(lib.hasPrefix "libx" (lib.getName p) && lib.getName p != "libxkbcommon")
          ) prevAttrs.buildInputs;
        }
      );
    in
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
        zig
      ];

      buildInputs = [
        # glfw
        glfwNoX11
        _libepoxyNoX11
        # libepoxy
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
