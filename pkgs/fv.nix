{
  packages.fv =
    {
      buildGoModule,
      fetchFromGitHub,
    }:
    let
      version = "0.5.6";
    in
    buildGoModule {
      pname = "fv";
      inherit version;
      src = fetchFromGitHub {
        owner = "kenshaw";
        repo = "fv";
        rev = "v${version}";
        hash = "sha256-sOQc7+LS35fS/2oddcR3wPyasH6eC0epxg8ohtx3/hI=";
      };
      vendorHash = "sha256-Sc8ZMfGR2Z0PDFU9YBF1ErLT6t3NTILZDuofhxcSYj4=";
    };
}
