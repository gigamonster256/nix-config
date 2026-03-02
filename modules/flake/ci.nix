{
  inputs,
  lib,
  config,
  ...
}:
let
  mkSpec =
    _system:
    {
      nixos ? [ ],
      darwin ? [ ],
      home ? [ ],
      artifacts ? { },
    }:
    let
      nixosAttrs = lib.genAttrs nixos (
        hostname: inputs.self.nixosConfigurations.${hostname}.config.system.build.toplevel
      );
      darwinAttrs = lib.genAttrs darwin (
        hostname: inputs.self.darwinConfigurations.${hostname}.config.system.build.toplevel
      );
      homeAttrs = lib.genAttrs home (
        homename: inputs.self.homeConfigurations.${homename}.config.home.activationPackage
      );
    in
    {
      inherit artifacts;
      cachix = nixosAttrs // darwinAttrs // homeAttrs;
    };
  systemSubmodule = lib.types.submodule {
    options = {
      nixos = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Hostnames of nixos configurations to build for this system.";
      };
      darwin = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Hostnames of darwin configurations to build for this system.";
      };
      home = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Hostnames of home configurations to build for this system.";
      };
      artifacts = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        default = { };
        description = "Artifacts to build for this system.";
      };
    };
  };
in
{
  options = {
    # TODO: introspect the nixosConfigurations, darwinConfigurations, and homeConfigurations
    # to automatically generate these lists instead of maintaining them manually?
    # or have opt in as a nixos/darwin/home configuration option which is read by the flake?
    ci = lib.mkOption {
      type = lib.types.attrsOf systemSubmodule;
      default = { };
      description = "CI configuration for nix-github-actions.";
    };
  };
  config = {
    flake =
      let
        ciChecks = builtins.mapAttrs mkSpec config.ci;
      in
      {
        cachixActions = inputs.nix-github-actions.lib.mkGithubMatrix {
          checks = builtins.mapAttrs (_system: ci: ci.cachix) ciChecks;
          attrPrefix = "cachixActions.checks";
        };
        artifactActions = inputs.nix-github-actions.lib.mkGithubMatrix {
          checks = builtins.mapAttrs (_system: ci: ci.artifacts) ciChecks;
          attrPrefix = "artifactActions.checks";
        };
      };
  };
}
