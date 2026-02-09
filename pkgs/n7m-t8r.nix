{
  packages.n7m-t8r =
    {
      fetchFromGitHub,
      stdenvNoCC,
    }:
    stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "n7m-t8r";
      version = "0.0.3";

      src = fetchFromGitHub {
        owner = "gigamonster256";
        repo = "n7m-t8r";
        tag = "v${finalAttrs.version}";
        hash = "sha256-kCtm5BHhAt1mlucIkJeCnGSqXuioZZl713CHXQRSHkE=";
      };

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        mkdir -p $out
        cp index.html $out/
      '';
    });
}
