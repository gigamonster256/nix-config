{
  packages.umap =
    {
      lib,
      stdenv,
      fetchFromGitHub,
      fetchpatch2,
      cmake,
    }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "umap";
      version = "2.1.1";

      src = fetchFromGitHub {
        owner = "llnl";
        repo = "umap";
        tag = "v${finalAttrs.version}";
        hash = "sha256-nAzQ7fK9BsfgOSWuoQLeqomy6LO+ERP0fjj12iQXp5I=";
      };

      patches = [
        # update for recent c++ compiler
        (fetchpatch2 {
          url = "https://github.com/llnl/umap/pull/129.patch?full_index=1";
          hash = "sha256-jnRKUOM5pHn6LOEiG+2NbhsceBgL3c60QsBgXB3s4EE=";
        })
      ];

      nativeBuildInputs = [
        cmake
      ];

      meta = {
        description = "User-space Page Management";
        homepage = "https://github.com/llnl/umap";
        license = lib.licenses.lgpl21Only;
      };
    });
}
