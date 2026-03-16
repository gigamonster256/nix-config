{
  nixpkgs.allowedUnfreePackages = [
    "wiiu-title-keys"
  ];

  packages.wiiu-title-keys =
    {
      lib,
      stdenvNoCC,
      cacert,
      curl,
      coreutils,
    }:
    stdenvNoCC.mkDerivation {
      name = "wiiu-title-keys";

      impureEnvVars = lib.fetchers.proxyImpureEnvVars;

      nativeBuildInputs = [
        curl
        coreutils
      ];

      env.SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      # remove header which includes date and is thus non-reproducible
      installPhase = ''
        curl --user-agent "NUSspliBuilder/2.1" "https://napi.v10lator.de/db?t=go" | tail -n +6 > $out
      '';

      outputHash = "sha256-8euB/LbRL1X9rE7q0zcxO4nhZ/hg6i58H+mg7Rw9/oE=";
      outputHashAlgo = "sha256";

      meta.license = lib.licenses.unfree;
    };

  # # has date in contents - so non-reproducible
  # packages.wiiu-title-keys =
  #   {
  #     lib,
  #     fetchurl,
  #   }:
  #   fetchurl {
  #     name = "wiiu-title-keys";
  #     url = "https://napi.v10lator.de/db?t=go";
  #     hash = "sha256-zlUuLox1qGPjQ22BCHYG3euLm+tBl9W7alej1seHIxA=";
  #     curlOptsList = [
  #       "--user-agent"
  #       "NUSspliBuilder/2.1"
  #     ];
  #     meta.license = lib.licenses.unfree;
  #   };

  packages.wiiu-downloader =
    {
      lib,
      buildGoModule,
      fetchFromGitHub,
      pkg-config,
      glib,
      cairo,
      gtk3,

      wiiu-title-keys,
    }:
    buildGoModule (finalAttrs: {
      pname = "wiiu-downloader";
      version = "2.82";

      src = fetchFromGitHub {
        owner = "Xpl0itU";
        repo = "WiiUDownloader";
        tag = "v${finalAttrs.version}";
        hash = "sha256-OXPS0elDIDBiUdoc4BForyggNgTi/RHwrhLCgmO8FhA=";
      };

      sourceRoot = "${finalAttrs.src.name}/cmd/WiiUDownloader";

      postUnpack = ''
        chmod +w ${finalAttrs.src.name}
        cp -f ${wiiu-title-keys} ${finalAttrs.src.name}/db.go
      '';

      # uses: replace github.com/Xpl0itU/WiiUDownloader => ../..
      proxyVendor = true;
      vendorHash = "sha256-U7zfy6dxUOiV1sTMQT0lkioEv1HJ93loQpcoDNa0k2U=";

      nativeBuildInputs = [
        pkg-config
      ];

      buildInputs = [
        glib
        cairo
        gtk3
      ];

      meta = {
        description = "Allows to download encrypted wiiu files from nintendo's official servers";
        homepage = "https://github.com/Xpl0itU/WiiUDownloader";
        downloadPage = "https://github.com/Xpl0itU/WiiUDownloader/releases";
        mainProgram = "WiiUDownloader";
        license = lib.licenses.gpl3Only;
      };
    });
}
