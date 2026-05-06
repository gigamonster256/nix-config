{
  packages.styx =
    {
      lib,
      buildGoModule,
      fetchFromGitHub,
      makeWrapper,
      tayga,
      provideTayga ? true,
    }:
    buildGoModule (finalAttrs: {
      name = "styx";
      version = "0.0.1-prev";

      src = fetchFromGitHub {
        owner = "apalrd";
        repo = "styx46";
        rev = "f7df5cdd532fe3ab29fb2f0d27de8b69a72c49d0";
        hash = "sha256-QJvL0XrMu7V9oF6keRc4uZBV2Ytxfjv5TbVVs1VgcRA=";
      };

      vendorHash = "sha256-Z3Wyo2vsGoJMdmuoB82uYKsAqlPqxOSyGEXm4tIizlY=";

      nativeBuildInputs = lib.optional provideTayga makeWrapper;

      # wrap binary to add tayga to PATH (overrideable with binary_path in styx.yaml)
      postInstall = lib.optionalString provideTayga ''
        wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
          --prefix PATH : "${lib.makeBinPath [ tayga ]}"
      '';

      # tests have not been updated
      doCheck = false;

      meta.mainProgram = "styx46";
    });
}
