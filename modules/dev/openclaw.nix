{
  # could use nixpkgs.permittedInsecurePackages but the "vulnerability"
  # will never go away, so just mark it as known and not vulnerable
  # instead of needing to bump the version every time the project updates
  nixpkgs.overlays = [
    (final: prev: {
      openclaw = prev.openclaw.overrideAttrs (prevAttrs: {

        patches = (prevAttrs.patches or [ ]) ++ [
          # upstream patch to fix completion
          (final.fetchpatch2 {
            url = "https://github.com/openclaw/openclaw/commit/a0b8870d48e80c238db58b930fd399a5e8267115.patch?full_index=1";
            hash = "sha256-jtxxXTmbtMy8Eam5hsWB/JQhWe9Hmfoz+Pt9kXeXRsE=";
          })
        ];

        nativeBuildInputs = (prevAttrs.nativeBuildInputs or [ ]) ++ [ final.installShellFiles ];

        # build and install completions (zsh bash fish powershell available)
        postInstall =
          final.lib.optionalString (final.stdenv.hostPlatform.emulatorAvailable final.buildPackages)
            (
              let
                emulator = final.stdenvNoCC.hostPlatform.emulator final.buildPackages;
              in
              ''
                installShellCompletion --cmd openclaw \
                  --bash <(${emulator} $out/bin/openclaw completion --shell bash) \
                  --fish <(${emulator} $out/bin/openclaw completion --shell fish) \
                  --zsh <(${emulator} $out/bin/openclaw completion --shell zsh)
              ''
            );

        # Project uses LLMs to parse untrusted content,
        # making it vulnerable to prompt injection,
        # while having full access to system by default.
        meta.knownVulnerabilities = [ ];
      });
    })
  ];

  flake.modules.homeManager.openclaw = {
    # TODO: harden? daemon? declarative openclaw.json as settings?
    programs.openclaw.enable = true;
  };

  persistence.wrappers.homeManager = [
    "openclaw"
  ];

  persistence.programs.homeManager = {
    openclaw = {
      directories = [ ".openclaw" ];
    };
  };
}
