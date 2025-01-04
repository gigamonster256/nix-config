{
  stdenv,
  lib,
  unzip,
  autoPatchelfHook,
  fetchurl,
  makeWrapper,
  alsa-lib,
  mesa,
  nss,
  nspr,
  systemd,
  makeDesktopItem,
  copyDesktopItems,
  wrapGAppsHook3,
  metaCommon,
}: let
  pname = "trilium-next-desktop";
  version = "0.90.12";

  source = os: arch: hash: {
    url = "https://github.com/TriliumNext/Notes/releases/download/v${version}/TriliumNextNotes-v${version}-${os}-${arch}.zip";
    inherit hash;
  };

  linuxSource = source "linux";
  darwinSource = source "macos";

  sources = {
    x86_64-linux = linuxSource "x64" lib.fakeHash;
    aarch64-linux = linuxSource "arm64" lib.fakeHash;
    x86_64-darwin = darwinSource "x64" lib.fakeHash;
    aarch64-darwin = darwinSource "arm64" "sha256-KFuL9bne9NkpXNSnm5iR1JhgtWrgdF4KGfETSLFswdg=";
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};

  meta =
    metaCommon
    // {
      mainProgram = "trilium";
      platforms = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
    };

  linux = stdenv.mkDerivation rec {
    inherit pname version meta src;

    # TODO: migrate off autoPatchelfHook and use nixpkgs' electron
    nativeBuildInputs = [
      unzip
      autoPatchelfHook
      makeWrapper
      wrapGAppsHook3
      copyDesktopItems
    ];

    buildInputs = [
      alsa-lib
      mesa
      nss
      nspr
      stdenv.cc.cc
      systemd
    ];

    desktopItems = [
      (makeDesktopItem {
        name = "Trilium";
        exec = "trilium";
        icon = "trilium";
        comment = meta.description;
        desktopName = "Trilium Notes";
        categories = ["Office"];
        startupWMClass = "trilium notes";
      })
    ];

    # Remove trilium-portable.sh, so trilium knows it is packaged making it stop auto generating a desktop item on launch
    postPatch = ''
      rm ./trilium-portable.sh
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      mkdir -p $out/share/trilium
      mkdir -p $out/share/icons/hicolor/128x128/apps

      cp -r ./* $out/share/trilium
      ln -s $out/share/trilium/trilium $out/bin/trilium

      ln -s $out/share/trilium/icon.png $out/share/icons/hicolor/128x128/apps/trilium.png
      runHook postInstall
    '';

    # LD_LIBRARY_PATH "shouldn't" be needed, remove when possible :)
    # Error: libstdc++.so.6: cannot open shared object file: No such file or directory
    preFixup = ''
      gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs})
    '';

    dontStrip = true;

    # passthru.updateScript = ./update.sh;
  };

  darwin = stdenv.mkDerivation {
    inherit pname version meta src;

    nativeBuildInputs = [unzip];

    installPhase = ''
      mkdir -p $out/Applications
      cp -r '../TriliumNext Notes.app' $out/Applications
    '';
  };
in
  if stdenv.hostPlatform.isDarwin
  then darwin
  else linux
