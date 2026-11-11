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
        curl --compressed --user-agent "NUSspliBuilder/2.2" "https://napi.v10lator.de/db?t=go" | tail -n +6 > $out
      '';

      outputHash = "sha256-8euB/LbRL1X9rE7q0zcxO4nhZ/hg6i58H+mg7Rw9/oE=";
      outputHashAlgo = "sha256";

      meta.license = lib.licenses.unfree;
    };

  packages.wiiu-downloader =
    {
      lib,
      buildGoModule,
      fetchFromGitHub,
      pkg-config,
      gdk-pixbuf,
      glib,
      gobject-introspection,
      gtk4,
      libadwaita,
      libgcrypt,
      librsvg,

      wiiu-title-keys,
    }:
    buildGoModule (finalAttrs: {
      pname = "wiiu-downloader";
      version = "3.2";

      src = fetchFromGitHub {
        owner = "Xpl0itU";
        repo = "WiiUDownloader";
        tag = "v${finalAttrs.version}";
        hash = "sha256-mCiYRoEwWtDQwQy9gFOAlcnsMyB4I1jW5h6NIIRLjGg=";
      };

      sourceRoot = "${finalAttrs.src.name}/cmd/WiiUDownloader";

      # Mirrors upstream CI: https://github.com/Xpl0itU/WiiUDownloader/blob/v2.94/.github/workflows/linux.yml
      postUnpack = ''
        chmod +w ${finalAttrs.src.name}
        {
          sed -e '/^type TitleEntry struct/,/^}/d' \
              -e 's/^var titleEntry =/func init() { TitleDatabase =/' \
              ${wiiu-title-keys}
          echo '}'
        } > ${finalAttrs.src.name}/db.go
      '';

      # uses: replace github.com/Xpl0itU/WiiUDownloader => ../..
      proxyVendor = true;
      vendorHash = "sha256-0RmHPv2NjbkgeQrVmmJdvN7uD87PDtbsmNPeSflNBHc=";

      nativeBuildInputs = [
        pkg-config
      ];

      buildInputs = [
        gdk-pixbuf
        glib
        gobject-introspection
        gtk4
        libadwaita
        libgcrypt
        librsvg
      ];

      meta = {
        description = "Allows to download encrypted wiiu files from nintendo's official servers";
        homepage = "https://github.com/Xpl0itU/WiiUDownloader";
        downloadPage = "https://github.com/Xpl0itU/WiiUDownloader/releases";
        maintainers = [ lib.maintainers.gigamonster256 ];
        mainProgram = "WiiUDownloader";
        license = lib.licenses.gpl3Only;
      };
    });
}
