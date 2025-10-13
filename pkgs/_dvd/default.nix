let
  dvd =
    {
      lib,
      buildGoModule,
      fetchFromGitHub,
    }:
    buildGoModule (finalAttrs: {
      pname = "dvd";
      version = "1.0.0";
      src = fetchFromGitHub {
        owner = "integrii";
        repo = "dvd";
        tag = "v${finalAttrs.version}";
        sha256 = "sha256-CiDBLGoFpIe/qD/PwLbrZMXe+antm0TnaZEMSY5nJts=";
      };

      patches = [ ./version.patch ]; # https://nixpk.gs/pr-tracker.html?pr=441125
      vendorHash = "sha256-L7nK+w4CB2H3b6vL0ZoFfaRMgCmpqzQo8ThMM60C76I=";

      meta = {
        description = "Bouncing DVD screen saver for your terminal";
        homepage = "https://github.com/integrii/dvd";
        license = lib.licenses.unlicense;
      };
    });
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.dvd = pkgs.callPackage dvd { };
    };
}
