{
  packages.iv =
    {
      lib,
      buildGoModule,
      fetchFromGitHub,
      pkg-config,
      resvg,
      vips,
    }:
    buildGoModule (finalAttrs: {
      pname = "iv";
      version = "0.11.1";

      src = fetchFromGitHub {
        owner = "kenshaw";
        repo = "iv";
        tag = "v${finalAttrs.version}";
        hash = "sha256-QbSni6sdQ6KpX5XgpxaNWRLigiswHK2UV2kRdIR5boU=";
      };
      vendorHash = "sha256-o4Pk2cll1k/LsW9c7PHyby7ogMvCfCNxpsT72visM5M=";

      nativeBuildInputs = [
        pkg-config
      ];

      buildInputs = [
        resvg
        vips
      ];

      meta = {
        description = "A command-line image viewer using terminal graphics ";
        homepage = "https://github.com/kenshaw/iv";
        license = lib.licenses.mit;
      };
    });
}
