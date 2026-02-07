{
  packages.n7m-t8r =
    {
      fetchFromGitHub,
      stdenvNoCC,
    }:
    stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "n7m-t8r";
      version = "0.0.1";

      src = fetchFromGitHub {
        owner = "gigamonster256";
        repo = "n7m-t8r";
        tag = "v${finalAttrs.version}";
        hash = "sha256-g+4IjrvQG5UcVUvEUlNgh0RgIMRVT6rqFYTS3cXmWHA=";
      };

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        mkdir -p $out
        cp index.html $out/
      '';
    });
}
