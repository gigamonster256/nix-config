{
  packages.jj-ryu =
    {
      lib,
      fetchFromGitHub,
      rustPlatform,
      git,
      jujutsu,
    }:
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "jj-ryu";
      version = "0.0.1-alpha.11";

      src = fetchFromGitHub {
        owner = "dmmulroy";
        repo = "jj-ryu";
        tag = "v${finalAttrs.version}";
        hash = "sha256-gE4lvqyC2LRAWNDUGePklORWjyEofs/dHLHVBAub424=";
      };

      cargoHash = "sha256-OD1DpV4s6tgOnDEAfJWScdSKqtYArbqIJVClOtUCYa4=";

      nativeCheckInputs = [ git jujutsu ];

      meta = {
        description = "Stacked PRs for Jujutsu";
        homepage = "https://github.com/dmmulroy/jj-ryu";
        # license =
        # maintainers = with maintainers; [ ];
        mainProgram = "ryu";
      };
    });
}
