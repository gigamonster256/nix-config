{
  packages.jj-ryu =
    {
      lib,
      fetchFromGitHub,
      rustPlatform,
      jujutsu,
    }:
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "jj-ryu";
      version = "0.0.1-alpha.8";

      src = fetchFromGitHub {
        owner = "dmmulroy";
        repo = "jj-ryu";
        tag = "v${finalAttrs.version}";
        hash = "sha256-Bu36QhHKawZiDN8+0hnltjm4m+ulQmvHUYjqodRHsE8=";
      };

      cargoHash = "sha256-uKAQ3yuPIO4nXKUCuMSjqQCQ0WEWKlBWJtuaA60jGvA=";

      nativeCheckInputs = [ jujutsu ];

      meta = with lib; {
        description = "Stacked PRs for Jujutsu";
        homepage = "https://github.com/dmmulroy/jj-ryu";
        # license =
        # maintainers = with maintainers; [ ];
        mainProgram = "ryu";
      };
    });
}
