{
  packages.jj-gpc =
    {
      lib,
      fetchFromGitHub,
      rustPlatform,
      pkg-config,
      openssl,
      makeWrapper,
      prefix ? null, # override at higher level?
    }:
    let
      hasPrefix = prefix != null;
    in
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "jj-gpc";
      version = "0.7.3";

      src = fetchFromGitHub {
        owner = "chriskrycho";
        repo = "jj-gpc";
        tag = "v${finalAttrs.version}";
        hash = "sha256-S9TO8OqgkqEEn08yED+6lHfBEQ7IQFgJYalEx4D4VNY=";
      };

      cargoHash = "sha256-OrRfwClj9WWeFGBH2DiW8Lg2hn8wVjF6/Rfx5M8qg+M=";

      nativeBuildInputs = [
        pkg-config
      ]
      ++ lib.optional hasPrefix makeWrapper;

      buildInputs = [
        openssl
      ];

      postInstall = lib.optionalString hasPrefix ''
        wrapProgram $out/bin/jj-gpc \
          --add-flag --prefix=${prefix}
      '';

      meta = {
        description = "LLM-based bookmark name creation for Jujutsu";
        homepage = "https://github.com/chriskrycho/jj-gpc";
        license = lib.licenses.blueOak100;
        # maintainers = with maintainers; [ ];
        mainProgram = "jj-gpc";
      };
    });
}
