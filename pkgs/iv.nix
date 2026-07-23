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
      version = "0.13.4";

      src = fetchFromGitHub {
        owner = "kenshaw";
        repo = "iv";
        tag = "v${finalAttrs.version}";
        hash = "sha256-BWJB4gMWq8vyVZuLD1gbsJM7nkHXhnPhKQllQ+M8n9s=";
      };
      vendorHash = "sha256-binUtUalY+MfcbqXtGjMhO0CY+XjZKhyjyvkJINkNrs=";

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
