{
  inputs,
  lib,
  flake-parts-lib,
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
      packages ? { },
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
      cachix = nixosAttrs // darwinAttrs // homeAttrs // packages;
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
      # TODO: coerce strings into self packages to simplify flake.ci.arch.name = self.packages.arch.name usage?
      packages = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        default = { };
        description = "Packages to build for this system.";
      };
      artifacts = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        default = { };
        description = "Artifacts to build for this system.";
      };
    };
  };
in
# FIXME: use mkTransposedPerSystemModule but don't expose the ci options as rendered into flake outputs?
lib.recursiveUpdate
  (flake-parts-lib.mkTransposedPerSystemModule {
    name = "ci";
    option = lib.mkOption {
      type = systemSubmodule;
      default = { };
      description = "CI configuration for nix-github-actions.";
    };
    file = ./ci.nix;
  })
  {
    config.flake =
      let
        ciChecks = builtins.mapAttrs mkSpec config.flake.ci;
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
  }
