{
  packages.n7m-t8r =
    {
      buildNpmPackage,
      fetchFromGitHub,
      imagemagick,
    }:
    buildNpmPackage (finalAttrs: {
      pname = "n7m-t8r";
      version = "0.0.4";

      src = fetchFromGitHub {
        owner = "gigamonster256";
        repo = "n7m-t8r";
        tag = "v${finalAttrs.version}";
        hash = "sha256-hCMcWHB2nQCVnf18fCQEq2A4/IgumtfbMrAcIciqaco=";
      };

      npmDepsHash = "sha256-PLN0yEBYkBbfMpg9npwNdun36mgWwPVU9WA/j5+VDf0=";

      nativeBuildInputs = [ imagemagick ];

      installPhase = ''
        mkdir -p $out/
        cp -r dist/* $out/
      '';
    });
}
