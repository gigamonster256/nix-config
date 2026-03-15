{ self, ... }:
{
  flake.ci.x86_64-linux.packages = { inherit (self.packages.x86_64-linux) gem5; };

  packages.gem5 =
    {
      lib,
      stdenv,
      fetchFromGitHub,
      scons,
      pkg-config,
      python3,
      boost,
      gperftools,
      zlib,
      hdf5,
      capstone,
      protobuf,
      abseil-cpp,
      gnum4,
      libpng,
      valgrind,
      ISA ? "ALL",
      variant ? "opt", # debug, opt, or fast
      withValgrind ? stdenv.hostPlatform.isLinux,
    }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "gem5";
      version = "25.1.0.0";

      src = fetchFromGitHub {
        owner = "gem5";
        repo = "gem5";
        tag = "v${finalAttrs.version}";
        sha256 = "sha256-0goJSUGR0PJe9DEbxhKUHSlkfc8Gqqnd8Pwn8cZigFw=";
      };

      nativeBuildInputs = [
        scons
        pkg-config
      ];

      buildInputs = [
        python3
        gperftools
        boost
        zlib
        hdf5
        capstone
        protobuf
        gnum4
        libpng
        abseil-cpp
      ]
      ++ lib.optional withValgrind valgrind;

      enableParallelBuilding = true;

      postPatch = ''
        patchShebangs --build util build_tools ext/Kconfiglib

        substituteInPlace src/base/date.cc \
          --replace-fail '__DATE__' "\"$(date -ud "@$SOURCE_DATE_EPOCH" +'%b %d %Y')\"" \
          --replace-fail '__TIME__' "\"$(date -ud "@$SOURCE_DATE_EPOCH" +'%T')\""
      '';

      buildFlags = [
        "build/${ISA}/gem5.${variant}"
      ];

      installPhase = ''
        mkdir -p $out/bin
        cp -a build/${ISA}/gem5.${variant} $out/bin/gem5
      '';

      meta = {
        homepage = "https://gem5.org";
        mainProgram = "gem5";
      };
    });
}
