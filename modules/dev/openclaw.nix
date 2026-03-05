{
  # could use nixpkgs.permittedInsecurePackages but the "vulnerability"
  # will never go away, so just mark it as known and not vulnerable
  # instead of needing to bump the version every time the project updates
  nixpkgs.overlays = [
    (_final: prev: {
      openclaw = prev.openclaw.overrideAttrs {
        # Project uses LLMs to parse untrusted content,
        # making it vulnerable to prompt injection,
        # while having full access to system by default.
        meta.knownVulnerabilities = [ ];
      };
    })
  ];

  unify.modules.openclaw.home = {
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
