{
  packages.styx =
    {
      lib,
      buildGoModule,
      fetchFromGitHub,
      fetchpatch2,
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
        rev = "3702e45a0eaccba875ad3503d9e92ba080b864e5";
        hash = "sha256-Gsbk657zbZEbcZtXJu8m0eQAfuNEGF3kkym5Bz4Fbrs=";
      };

      patches = [
        # default tayga path
        (fetchpatch2 {
          url = "https://github.com/apalrd/styx46/pull/2.patch?full_index=1";
          hash = "sha256-u5KUBetXZITedWptSZnAvfO91ITdIoOxfrMYPlMeXT0=";
        })
      ];

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
