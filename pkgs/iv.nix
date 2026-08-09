{
  autoUpdatePackages.iv = { };

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
      version = "0.14.1";

      src = fetchFromGitHub {
        owner = "kenshaw";
        repo = "iv";
        tag = "v${finalAttrs.version}";
        hash = "sha256-TG3p623/aXt+cMCB9Qq/rnDd41P45ltoicCrR4gNJtM=";
      };
      vendorHash = "sha256-nYtWzM0g1cmARkjRDDgUJSDSV+y1INx/lz/buc0DLTg=";

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
        maintainers = [ lib.maintainers.gigamonster256 ];
      };
    });
}
