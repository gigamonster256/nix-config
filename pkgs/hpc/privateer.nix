{
  packages.privateer =
    {
      lib,
      stdenv,
      fetchFromGitHub,
      cmake,
      boost,
      openssl,
    }:
    stdenv.mkDerivation (_finalAttrs: {
      pname = "privateer";
      version = "0.0.1";

      src = fetchFromGitHub {
        owner = "llnl";
        repo = "Privateer";
        rev = "dcb5a8086a7d1c700e8585413ecc394b1834463d";
        hash = "sha256-e1687oHDRf6/KL0T69DMNVXs3+24qFew4rTLuEpkjzY=";
      };

      nativeBuildInputs = [
        cmake
        boost
        openssl
      ];

      meta = {
        description = "Multi-versioned memory-mapped data stores for high-performance data science";
        homepage = "https://github.com/llnl/Privateer";
        license = lib.licenses.mit;
      };
    });
}
