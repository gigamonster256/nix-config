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
        mkdir -p $out/share/n7m-t8r
        cp -r dist/* $out/share/n7m-t8r/
      '';
    });

  perSystem =
    { pkgs, ... }:
    {
      apps.n7m-t8r.program = pkgs.writeShellApplication {
        name = "n7m-t8r";
        runtimeInputs = [ pkgs.python3 ];
        text = "python3 -m http.server --directory ${pkgs.n7m-t8r}/share/n7m-t8r --bind 127.0.0.1 8081";
      };
    };
}
