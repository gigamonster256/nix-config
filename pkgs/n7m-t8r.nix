{
  packages.n7m-t8r =
    {
      buildNpmPackage,
      fetchFromGitHub,
      imagemagick,
    }:
    buildNpmPackage (finalAttrs: {
      pname = "n7m-t8r";
      version = "0.0.5";

      src = fetchFromGitHub {
        owner = "gigamonster256";
        repo = "n7m-t8r";
        tag = "v${finalAttrs.version}";
        hash = "sha256-vrHgO8mAl5SSQcAuSMPIJRcLAeNAX9GptLAk1RLDF7E=";
      };

      npmDepsHash = "sha256-K4yQZdv3zN2p3by0EaIA7ej8sbsfN9IurDHNeWUIBJc=";

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
