{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  git,
  esbuild,
  buildGoModule,
  electron_31-bin,
  xcodebuild,
}: let
  # specify the esbuild version to use
  esbuild' = let
    version = "0.21.5";
  in
    esbuild.override {
      buildGoModule = args:
        buildGoModule (args
          // {
            inherit version;
            src = fetchFromGitHub {
              owner = "evanw";
              repo = "esbuild";
              rev = "v${version}";
              hash = "sha256-FpvXWIlt67G8w3pBKZo/mcp57LunxDmRUaCU/Ne89B8=";
            };
            vendorHash = "sha256-+BfxCyg0KkDQpHt/wycy/8CTG6YBA/VJvJFhhzUnSiQ=";
          });
    };

  # build an electron cache based on a specific version of electron
  # https://www.electronjs.org/docs/latest/tutorial/installation#cache
  electron_cache = {electron-bin}:
    stdenv.mkDerivation {
      pname = "electron-cache";
      inherit (electron-bin) src version;
      dontUnpack = true;
      installPhase = let
        # shasum not needed since we can overload the electron zip dir in forge config
        shasum = builtins.hashString "sha256" (dirOf electron-bin.src.url);
        zipName = baseNameOf electron-bin.src.url;
      in ''
        # mkdir -p $out/${shasum}
        # cp $src $out/${shasum}/${zipName}
        mkdir -p $out
        cp -r $src $out/${zipName}
      '';
    };

  electron_31_cache = electron_cache {
    electron-bin = electron_31-bin;
  };
in
  buildNpmPackage {
    pname = "trilium-next";
    version = "0.90.3-dev";

    src = fetchFromGitHub {
      owner = "TriliumNext";
      repo = "Notes";
      rev = "develop";
      hash = "sha256-dcRHrM7fCnoY6xBiibuMYCif7OR/083L7/FZ0/Jq8LY=";
    };

    npmDepsHash = "sha256-a5V610Kj5iW4nusq+EdKvuAEYYvva1xw3HFQuMD9OKY=";
    makeCacheWritable = true;

    nativeBuildInputs = [git] ++ lib.optional stdenv.isDarwin xcodebuild;

    env = {
      ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
      # electron_config_cache = "${electron_31_cache}";
      ESBUILD_BINARY_PATH = lib.getExe esbuild';
    };

    # add electron cache to the forge.config.cjs
    # https://electron.github.io/packager/main/interfaces/Options.html#electronZipDir
    patchPhase = ''
      runHook prePatch

      sed -i "31i     ,electronZipDir: '${electron_31_cache}'," forge.config.cjs

      runHook postPatch
    '';

    # build native app
    buildPhase = ''
      runHook preBuild

      npm run webpack
      npm run prepare-dist
      npx electron-forge package

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      # get build folder in ./out (only one should exist)
      app_folder="$(ls ./out)"

      mkdir -p $out/Applications
      cp -r ./out/"$app_folder"/*.app $out/Applications

      runHook postInstall
    '';

    meta = with lib; {
      description = "Trilium Next Notes";
      homepage = "https://github.com/TriliumNext/Notes";
      license = licenses.agpl3Plus;
    };
  }
