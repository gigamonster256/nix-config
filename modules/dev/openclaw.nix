{
  # could use nixpkgs.permittedInsecurePackages but the "vulnerability"
  # will never go away, so just mark it as known and not vulnerable
  # instead of needing to bump the version every time the project updates
  nixpkgs.overlays = [
    (_final: prev: {
      openclaw = prev.openclaw.overrideAttrs (old: {
        # Project uses LLMs to parse untrusted content,
        # making it vulnerable to prompt injection,
        # while having full access to system by default.
        meta = old.meta // {
          knownVulnerabilities = [ ];
        };
      });
    })
  ];

  # TODO: better module place? - pull port from option?
  flake.modules.nixos.default.services.proxy-dev.hosts.openclaw = 18789;

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
