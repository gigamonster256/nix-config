{
  packages.tayga =
    {
      lib,
      stdenv,
      fetchFromGitHub,
      nixosTests,
    }:
    stdenv.mkDerivation (finalAttrs: {
      # TODO: back to releases once map file feature is stable
      version = "0.9.7-prev";
      pname = "tayga";

      src = fetchFromGitHub {
        owner = "apalrd";
        repo = "tayga";
        rev = "8a028c787c86389a75dd4ef8cc01c9501133e966";
        hash = "sha256-47xdE1xBpNwdYhqPvuzRVsFyLoNQhgtmvhj8jWg5JnE=";
      };

      makeFlags = [ "CC=${lib.getExe stdenv.cc}" ];

      env = lib.optionalAttrs stdenv.hostPlatform.is32bit {
        NIX_CFLAGS_COMPILE = "-D_TIME_BITS=64 -D_FILE_OFFSET_BITS=64";
      };

      # TODO: better schema once a landed version has these defines
      preBuild = ''
        echo "#define TAYGA_VERSION \"${finalAttrs.version}\"" > version.h
        echo "#define TAYGA_BRANCH \"${finalAttrs.src.rev}\"" >> version.h
        echo "#define TAYGA_COMMIT \"${finalAttrs.src.rev}\"" >> version.h
      '';

      installPhase = ''
        install -Dm755 tayga $out/bin/tayga
        install -D tayga.conf.5 $out/share/man/man5/tayga.conf.5
        install -D tayga.8 $out/share/man/man8/tayga.8
        cp -R docs $out/share/
        cp tayga.conf.example $out/share/docs/
      '';

      passthru.tests.tayga = nixosTests.tayga;

      meta = {
        description = "Userland stateless NAT64 daemon";
        longDescription = ''
          TAYGA is an out-of-kernel stateless NAT64 implementation
          for Linux that uses the TUN driver to exchange IPv4 and
          IPv6 packets with the kernel.
          It is intended to provide production-quality NAT64 service
          for networks where dedicated NAT64 hardware would be overkill.
        '';
        homepage = "https://github.com/apalrd/tayga";
        license = lib.licenses.gpl2Plus;
        # maintainers = with lib.maintainers; [ _0x4A6F ];
        platforms = lib.platforms.linux;
        mainProgram = "tayga";
      };
    });
}
