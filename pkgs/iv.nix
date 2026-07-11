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
      version = "0.13.3";

      src = fetchFromGitHub {
        owner = "kenshaw";
        repo = "iv";
        tag = "v${finalAttrs.version}";
        hash = "sha256-msJLb1Qkx8GeWA7o1ZlJW0PEaCZ+TbU1KXpEvUkbBbE=";
      };
      vendorHash = "sha256-BrECPxGqFDEkzX4YYSXKv0h7fDwTBPqT7Yy0+U6gp/A=";

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
