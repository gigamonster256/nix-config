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
      version = "1.0.4";

      src = fetchFromGitHub {
        owner = "fab918";
        repo = "nxformat";
        tag = "V${finalAttrs.version}";
        hash = "sha256-XTNBk58cl8TK+ESQen9wDOld1YqXCm4xOJTDpydr8MU=";
      };

      cargoHash = "sha256-ITHbQK/pF2LoF7U6+p45SBKt0OxbZg4SOSP3wyyLzgg=";
      cargoRoot = "ffi";
      buildAndTestSubdir = "ffi";
      dontCargoInstall = true;

      nativeBuildInputs = [
        llvmPackages.libllvm
        python3
      ];

      # nixpkgs' cargo setup hook sets ZSTD_SYS_USE_PKG_CONFIG=1, which makes
      # zstd-sys look for a system libzstd instead of building the copy bundled
      # with the crate. Upstream's release packaging expects and strips those
      # vendored zstd objects, so keep the bundled build.
      dontCargoUseSystemLibs = true;

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
