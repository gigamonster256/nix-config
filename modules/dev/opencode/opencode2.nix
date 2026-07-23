{
  autoUpdatePackages.opencode2 = {
    extraArgs = [ "--use-update-script" ];
  };

  packages.opencode2 =
    {
      stdenv,
      fetchurl,
      autoPatchelfHook,
      nix-update-script,
    }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "opencode";
      version = "0.0.0-next-15782";

      src =
        let
          npmName = {
            "x86_64-linux" = "cli-linux-x64";
          };
          inherit (stdenv.hostPlatform) system;
          name = npmName.${system};
        in
        fetchurl {
          url = "https://registry.npmjs.org/@opencode-ai/${name}/-/${name}-${finalAttrs.version}.tgz";
          hash = "sha256-BGaMpcroxuOCDPcuBGdZOId0ygTRS+4nntAxjn6lwlY=";
        };

      nativeBuildInputs = [ autoPatchelfHook ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/node_modules/opencode
        cp -r . $out/lib/node_modules/opencode

        mkdir -p $out/bin
        ln -s $out/lib/node_modules/opencode/bin/opencode2 $out/bin/opencode2

        runHook postInstall
      '';

      # strip truncates the bun-compile payload appended after the ELF
      dontStrip = true;

      passthru.updateScript = nix-update-script {
        extraArgs = [
          "--flake"
          "--version=branch=next"
        ];
      };

      meta.platforms = [ "x86_64-linux" ];
      meta.mainProgram = "opencode2";
    });
}
