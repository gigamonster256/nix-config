{
  autoUpdatePackages.n7m-t8r = { };

  packages.n7m-t8r =
    {
      lib,
      buildNpmPackage,
      fetchFromGitHub,
      imagemagick,
    }:
    buildNpmPackage (finalAttrs: {
      pname = "n7m-t8r";
      version = "0.0.7";

      src = fetchFromGitHub {
        owner = "gigamonster256";
        repo = "n7m-t8r";
        tag = "v${finalAttrs.version}";
        hash = "sha256-b1aLgWx6ZKZM4HMCvGO03w6Iw/YJ6z+5vU8BS7/Vml4=";
      };

      npmDepsHash = "sha256-uaxYcW1Sgcfcm5MzdHd1t5nVMtEpto1c+UhUAnrD7To=";

      nativeBuildInputs = [ imagemagick ];

      installPhase = ''
        mkdir -p $out/share/n7m-t8r
        cp -r dist/* $out/share/n7m-t8r/
      '';

      meta = {
        description = "Numeronym Translator";
        homepage = "https://github.com/gigamonster256/n7m-t8r";
        maintainers = [ lib.maintainers.gigamonster256 ];
      };
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
