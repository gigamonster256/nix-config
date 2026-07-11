{
  autoUpdatePackages.hunk = { };

  packages.hunk =
    {
      lib,
      stdenv,
      fetchurl,
      autoPatchelfHook,
    }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "hunk";
      version = "0.17.0";

      src = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-linux-x64.tar.gz";
        hash = "sha256-DGJvemaHqYJjBOod9pbaXUnt+EJx7M31f//1g0KJ4OI=";
      };

      nativeBuildInputs = [
        autoPatchelfHook
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        cp hunk $out/bin/hunk
        chmod +x $out/bin/hunk
        runHook postInstall
      '';

      # strip truncates the bun-compile payload appended after the ELF
      dontStrip = true;

      meta = {
        description = "Review-first terminal diff viewer for agentic coders";
        homepage = "https://github.com/modem-dev/hunk";
        license = lib.licenses.mit;
        maintainers = [ lib.maintainers.gigamonster256 ];
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        mainProgram = "hunk";
        platforms = [ "x86_64-linux" ];
      };
    });
}
