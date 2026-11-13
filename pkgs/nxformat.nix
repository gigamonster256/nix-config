{
  autoUpdatePackages.nxformat = { };

  packages.nxformat =
    {
      lib,
      stdenv,
      rustPlatform,
      fetchFromGitHub,
      llvmPackages,
      python3,
    }:
    let
      nxPlatform = if stdenv.hostPlatform.isAarch64 then "linux-arm64" else "linux-x64";
    in
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "nxformat";
      version = "1.0.3";

      src = fetchFromGitHub {
        owner = "fab918";
        repo = "nxformat";
        tag = "V${finalAttrs.version}";
        hash = "sha256-LkJsXe8HXrg4ONGVDS8otEqelDpPz8/x6qeSrO6LYlI=";
      };

      cargoHash = "sha256-voBj5pabKGwVeH5gk6t0EjvOLAAqUF1yPJmTZ2I7pYo=";
      cargoRoot = "ffi";
      buildAndTestSubdir = "ffi";
      dontCargoInstall = true;

      nativeBuildInputs = [
        llvmPackages.libllvm
        python3
      ];

      # llvmPackages.libllvm provides llvm-ar. Upstream's release script only
      # looks for it in the rustc sysroot, where rustup's llvm-tools installs
      # it, so point it at the llvm-ar on PATH instead.
      postPatch = ''
        substituteInPlace tools/package_release.py \
          --replace-fail \
            "    tool = Path(sysroot) / 'lib/rustlib' / host / 'bin' / ('llvm-ar.exe' if sys.platform == 'win32' else 'llvm-ar')" \
            "    tool = Path(shutil.which('llvm-ar') or 'llvm-ar')"
      '';

      installPhase = ''
        runHook preInstall

        libdir="$(dirname "$(find target -name libnxformat.so -print -quit)")"
        python3 tools/package_release.py \
          --platform ${nxPlatform} \
          --version "${finalAttrs.version}" \
          --lib-dir "$libdir" \
          --out dist-release

        mkdir -p $out
        tar -xzf "dist-release/nxformat-${finalAttrs.version}-${nxPlatform}.tar.gz" -C $out

        runHook postInstall
      '';

      meta = {
        description = "Library for reading and writing .nx game archives";
        homepage = "https://github.com/fab918/nxformat";
        license = lib.licenses.mit;
        platforms = lib.platforms.linux;
      };
    });
}
