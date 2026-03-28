{
  packages.agari =
    {
      fetchFromGitHub,
      rustPlatform,
    }:
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "agari";
      version = "0.21.0";

      src = fetchFromGitHub {
        owner = "rysb-dev";
        repo = "agari";
        tag = "v${finalAttrs.version}";
        hash = "sha256-0OE5XrqfBhpwwXqzSzmv5HaLZbascmpsJxhXLbUk0So=";
      };

      cargoHash = "sha256-VJ11erz8UvQ2c3kM66jqs5IO+kYYSv//4UGLzez6Tdw=";

      buildAndTestSubdir = "crates/agari-core";

      meta = {
        description = "Riichi Score Calculator";
        homepage = "https://github.com/rysb-dev/agari";
        mainProgram = "agari";
      };
    });

  packages.agari-wasm =
    {
      rustPlatform,
      agari,
      rustc,
      wasm-pack,
      wasm-bindgen-cli_0_2_108,
      writableTmpDirAsHomeHook,
    }:
    let
      wasm-bindgen-cli = wasm-bindgen-cli_0_2_108;
    in
    rustPlatform.buildRustPackage (_finalAttrs: {
      pname = "agari-wasm";
      inherit (agari) version;

      inherit (agari) src cargoHash;

      buildAndTestSubdir = "crates/agari-wasm";

      nativeBuildInputs = [
        writableTmpDirAsHomeHook
        rustc.llvmPackages.lld
        wasm-pack
        wasm-bindgen-cli
      ];

      buildPhase = ''
        wasm-pack build crates/agari-wasm --target web --mode no-install
      '';

      installPhase = ''
        mkdir -p $out/lib/agari-wasm
        cp -r crates/agari-wasm/pkg/* $out/lib/agari-wasm/
      '';
    });

  packages.agari-web =
    {
      buildNpmPackage,
      agari,
      agari-wasm,
    }:
    buildNpmPackage {
      pname = "agari-web";
      inherit (agari) version;

      inherit (agari) src;
      sourceRoot = "${agari.src.name}/web";

      npmDepsHash = "sha256-VT1DND2+CK8uuDedcJGKtbeBieAKfK6oedADbqrJF/A=";

      preBuild = ''
        cp -r ${agari-wasm}/lib/agari-wasm/* src/lib/wasm/
      '';

      installPhase = ''
        mkdir -p $out/share/agari-web
        cp -r dist/* $out/share/agari-web/
      '';
    };

  perSystem =
    { pkgs, ... }:
    {
      apps.agari-web.program = pkgs.writeShellApplication {
        name = "agari-web";
        runtimeInputs = [ pkgs.python3 ];
        text = "python3 -m http.server --directory ${pkgs.agari-web}/share/agari-web --bind 127.0.0.1 8080";
      };
    };
}
