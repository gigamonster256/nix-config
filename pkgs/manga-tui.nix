{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  cargo,
  rustc,
  darwin,
  openssl,
  pkg-config,
}: let
  version = "0.2.0";
  src = fetchFromGitHub {
    owner = "josueBarretogit";
    repo = "manga-tui";
    rev = "refs/tags/v${version}";
    sha256 = "sha256-rGdncPEHbjA86RB0NjWgmci3Dz2c92o3mgC3eCt8Nxs=";
  };
in
  rustPlatform.buildRustPackage {
    inherit version src;
    pname = "manga-tui";

    nativeBuildInputs = [pkg-config];

    buildInputs = [openssl] ++ lib.optional stdenv.isDarwin darwin.apple_sdk.frameworks.SystemConfiguration;

    cargoLock = {
      lockFile = "${src}/Cargo.lock";
      outputHashes = {
        "ratatui-image-1.0.5" = "sha256-bUPKCK3AKO5fnv7a8PApZTI0LPBShNBsvgyunLMdIqg=";
      };
    };

    meta = {
      description = "Terminal manga reader and downloader";
      homepage = "https://github.com/josueBarretogit/manga-tui";
      license = lib.licenses.mit;
      mainProgram = "manga-tui";
    };
  }
