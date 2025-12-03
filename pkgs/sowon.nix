{
  packages.sowon =
    {
      lib,
      stdenv,
      fetchFromGitHub,
      xorg,
      libGL,
      withPenger ? true,
    }:
    stdenv.mkDerivation {
      pname = "sowon";
      version = "0.1.0";

      src = fetchFromGitHub {
        owner = "tsoding";
        repo = "sowon";
        rev = "79b0f4fa3a3f3a6a702e9d25e69d9d7b1f011a06";
        hash = "sha256-bqedCIdxYON5UEJx6jimdeC5Fh90ElQ8ZeSIfq22U1s=";
      };

      # FIXME: RGFW has experimental support for Wayland with fallback to X11...
      # try to enable it sometime?
      buildInputs = [
        xorg.libX11
        xorg.libXrandr
        xorg.libXcursor
        xorg.libXext
        xorg.libXi
        libGL
      ];

      postPatch = ''
        # allow building without penger
        sed -i 's/-DPENGER//' Makefile
        # link required X11 cursor and ext libraries
        sed -i 's/-lX11/-lX11 -lXcursor -lXext/' Makefile
      '';

      # configure penger flag and disable X11 cursor/ext dlopening
      NIX_CFLAGS_COMPILE = [
        "-DRGFW_NO_X11_CURSOR_PRELOAD"
        "-DRGFW_NO_X11_EXT_PRELOAD"
      ]
      ++ lib.optional withPenger "-DPENGER";

      makeFlags = [ "PREFIX=$(out)" ];

      meta = {
        description = "Starting Soon Timer for Tsoding Streams";
        homepage = "https://github.com/tsoding/sowon";
        license = lib.licenses.mit;
        mainProgram = "sowon";
        platforms = lib.platforms.linux;
      };
    };
}
