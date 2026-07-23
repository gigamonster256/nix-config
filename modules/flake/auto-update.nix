{
  inputs,
  lib,
  config,
  ...
}:
let
  packageSubmodule = lib.types.submodule {
    options = {
      platform = lib.mkOption {
        type = lib.types.str;
        default = "x86_64-linux";
        description = ''
          System platform to evaluate the package on when updating.
          Determines which GHA runner the update job runs on.
        '';
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments to pass to nix-update.";
      };
    };
  };
in
{
  options.autoUpdatePackages = lib.mkOption {
    type = lib.types.attrsOf packageSubmodule;
    default = { };
    description = ''
      Packages to auto-update via nix-update CI.
      Keys are flake package attribute names; values configure platform and extra args.
    '';
  };

  config.flake.autoUpdateMatrix =
    let
      packages = config.autoUpdatePackages;
      # { system = { name = derivation; }; }
      checks = lib.pipe packages [
        (lib.mapAttrsToList (
          name: cfg: {
            inherit name;
            inherit (cfg) extraArgs;
            system = cfg.platform;
            drv = inputs.self.packages.${cfg.platform}.${name} or null;
          }
        ))
        (builtins.filter (p: p.drv != null))
        (lib.foldl' (
          acc: pkg:
          acc
          // {
            ${pkg.system} = (acc.${pkg.system} or { }) // {
              ${pkg.name} = pkg.drv;
            };
          }
        ) { })
      ];

      result = inputs.nix-github-actions.lib.mkGithubMatrix {
        inherit checks;
        attrPrefix = "autoUpdateMatrix.checks";
      };

      extraArgs = builtins.listToAttrs (
        lib.mapAttrsToList (name: cfg: {
          inherit name;
          value = lib.concatStringsSep " " cfg.extraArgs;
        }) packages
      );

      include = map (
        entry:
        entry
        // {
          extraArgs = extraArgs.${entry.name} or "";
        }
      ) result.matrix.include;
    in
    {
      inherit include;
    };
}
