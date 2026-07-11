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
      version = "0.0.1-alpha.10";

      src = fetchFromGitHub {
        owner = "dmmulroy";
        repo = "jj-ryu";
        tag = "v${finalAttrs.version}";
        hash = "sha256-q7uSlVVVs2Y3aFsO2gTIIB1FiAaGuq/VewC72M43QNc=";
      };

      cargoHash = "sha256-tY3b4vt4aUUWV1dUZEaYaAg9RNiF/bbshQMYGo8gnrA=";

      nativeCheckInputs = [
        git
        jujutsu
      ];

      meta = {
        description = "Stacked PRs for Jujutsu";
        homepage = "https://github.com/dmmulroy/jj-ryu";
        # license =
        maintainers = [ lib.maintainers.gigamonster256 ];
        mainProgram = "ryu";
      };
    });
}
