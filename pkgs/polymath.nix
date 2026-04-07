{
  nixpkgs.allowedUnfreePackages = [
    "polymath"
  ];

  packages.polymath =
    {
      lib,
      fetchurl,
      stdenv,
      dpkg,
      autoPatchelfHook,
      makeWrapper,
      libcxx,
      gtk3,
      glib,
      mpv-unwrapped,
      ffmpeg,
      libgbm,
      libserialport,
      libusb1,
      ayatana-ido,
      libayatana-appindicator,
      xprop,
    }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "polymath";
      version = "1.4.0.7";

      src = fetchurl {
        url = "https://fluxkeyboard.com/updates/polymath/linux/deb/polymath_${finalAttrs.version}_amd64.deb";
        hash = "sha256-EYLBTd9r0s3Bxm4Gy8wbCNS0dyuXLI1jt6raSzrP/00=";
      };

      nativeBuildInputs = [
        dpkg
        autoPatchelfHook
        makeWrapper
      ];

      buildInputs = [
        libcxx
        gtk3
        glib
        mpv-unwrapped
        ffmpeg
        libgbm
        libserialport
        libusb1
        ayatana-ido
        libayatana-appindicator
      ];

      # FIXME: polymath puts files in $HOME/flux which is quite annoying - ask for it to honor XDG_CONFIG_HOME or similar
      installPhase = ''
        runHook preInstall

        # udev and polkit rules
        mkdir -p $out/etc
        cp -r etc/* $out/etc/

        # desktop application and icon
        mkdir -p $out/share
        cp -r usr/share/* $out/share/

        # patch the desktop file to point to correct entries
        substituteInPlace $out/share/applications/polymath.desktop \
          --replace "Exec=/opt/polymath/polymath" "Exec=$out/bin/polymath" \
          --replace "Icon=/usr/share/pixmaps/polymath.png" "Icon=$out/share/pixmaps/polymath.png"

        # Keep the Flutter bundle structure intact
        mkdir -p $out/opt/polymath
        cp -r opt/polymath/* $out/opt/polymath/

        # Create wrapper script in bin/
        mkdir -p $out/bin
        makeWrapper $out/opt/polymath/polymath $out/bin/polymath \
          --chdir $out/opt/polymath \
          --prefix PATH : ${lib.makeBinPath [ xprop ]}

        runHook postInstall
      '';

      meta = {
        homepage = "https://fluxkeyboard.com";
        description = "Flux Keyboard Configuration";
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        license = lib.licenses.unfree;
        platforms = lib.platforms.linux;
        mainProgram = "polymath";
        downloadPage = "https://fluxkeyboard.com/updates";
      };
    });
}
