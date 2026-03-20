{
  # could use nixpkgs.permittedInsecurePackages but the "vulnerability"
  # will never go away, so just mark it as known and not vulnerable
  # instead of needing to bump the version every time the project updates
  nixpkgs.overlays = [
    (final: prev: {
      openclaw = prev.openclaw.overrideAttrs (
        finalAttrs: prevAttrs: {

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
                  installShellCompletion --cmd ${finalAttrs.meta.mainProgram} \
                    --bash <(${emulator} $out/bin/openclaw completion --shell bash) \
                    --fish <(${emulator} $out/bin/openclaw completion --shell fish) \
                    --zsh <(${emulator} $out/bin/openclaw completion --shell zsh)
                ''
              );

          # Project uses LLMs to parse untrusted content,
          # making it vulnerable to prompt injection,
          # while having full access to system by default.
          meta.knownVulnerabilities = [ ];
          meta.mainProgram = "openclaw";
        }
      );
    })
  ];

  flake.modules.homeManager.openclaw =
    { lib, config, ... }:
    {
      # TODO: harden? declarative openclaw.json as settings?
      programs.openclaw.enable = true;

      systemd.user.services.openclaw-gateway = lib.mkIf config.programs.openclaw.enable {
        Unit = {
          Description = "OpenClaw Gateway";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };

        Service =
          let
            port = toString 18789;
          in
          {
            ExecStart = "${lib.getExe config.programs.openclaw.package} gateway --port ${port}";
            Restart = "always";
            RestartSec = "5";
            KillMode = "process";
            Environment = [
              "OPENCLAW_GATEWAY_PORT=${port}"
              "OPENCLAW_GATEWAY_TOKEN=2566989a83d960baf2e96163e15136cf0f000a01726f1801"
              "OPENCLAW_SYSTEMD_UNIT=openclaw-gateway.service"
              "OPENCLAW_SERVICE_MARKER=openclaw"
              "OPENCLAW_SERVICE_KIND=gateway"
              "OPENCLAW_SERVICE_VERSION=${config.programs.openclaw.package.version}"
            ];
          };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
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
