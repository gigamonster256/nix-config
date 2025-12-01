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
        rev = "fc7e2996858118d9c91d2d5ef4ace1f6eda50101";
        hash = "sha256-wrEMs2wVW6KwaQ2YZYBdS8zHAVo4FlspSSanznnXINs=";
      };

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
        # only build/install sowon_rgfw
        sed -i 's/all: Makefile sowon sowon_rgfw man/all: Makefile sowon_rgfw man/' Makefile
        sed -i '\|\$(INSTALL) -C \./sowon |d' Makefile
        # link required X11 and Wayland libraries
        sed -i 's/-lX11/-lX11 -lXcursor -lXext -lXi/' Makefile
      '';

      # configure penger flag and disable X11 cursor/ext dlopening
      NIX_CFLAGS_COMPILE = [
        "-DRGFW_NO_X11_CURSOR_PRELOAD"
        "-DRGFW_NO_X11_EXT_PRELOAD"
      ]
      ++ lib.optional withPenger "-DPENGER";

      makeFlags = [ "PREFIX=$(out)" ];

      postInstall = ''
        mv $out/bin/sowon_rgfw $out/bin/sowon
      '';

      meta = {
        description = "Starting Soon Timer for Tsoding Streams";
        homepage = "https://github.com/tsoding/sowon";
        license = lib.licenses.mit;
        mainProgram = "sowon";
        platforms = lib.platforms.linux;
      };
    };
}
