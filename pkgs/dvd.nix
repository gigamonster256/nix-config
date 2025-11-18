{
  packages.dvd =
    {
      lib,
      buildGoModule,
      fetchFromGitHub,
    }:
    buildGoModule (finalAttrs: {
      pname = "dvd";
      version = "1.1.0";
      src = fetchFromGitHub {
        owner = "integrii";
        repo = "dvd";
        tag = "v${finalAttrs.version}";
        hash = "sha256-iCoHmBF0YxRpPgIUzC+0RUcBKTJXjQzWvrDZP7aclek=";
      };

      vendorHash = "sha256-L7nK+w4CB2H3b6vL0ZoFfaRMgCmpqzQo8ThMM60C76I=";

      meta = {
        description = "Bouncing DVD screen saver for your terminal";
        homepage = "https://github.com/integrii/dvd";
        license = lib.licenses.unlicense;
      };
    });
}
