let
  mkNixosHomeImpermanenceOption =
    {
      name,
      namespace,
      directories,
      files,
    }:
    { lib, config, ... }:
    let
      path = lib.splitString "." name;
      programPath = namespace ++ path;
      impermanencePath = programPath ++ [ "impermanence" ];
      getVal = p: default: lib.attrByPath p default config;
      impermanenceCfg = getVal impermanencePath { };
    in
    {
      options = lib.setAttrByPath impermanencePath {
        enable = (lib.mkEnableOption ("impermanence for " + name)) // {
          default = getVal (programPath ++ [ "enable" ]) false;
        };
        directories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = directories;
          description = "List of directories in home to persist for ${name}.";
        };
        files = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = files;
          description = "List of files in home to persist for ${name}.";
        };
      };

      config = lib.mkIf (impermanenceCfg.enable or false) {
        home-manager.sharedModules = [
          {
            impermanence = {
              inherit (impermanenceCfg) directories files;
            };
          }
        ];
      };
    };

  module =
    { lib, config, ... }:
    {
      options.impermanence.programs.nixos-home = lib.mkOption {
        type =
          with lib.types;
          attrsOf (
            submodule (_name: {
              options = {
                namespace = lib.mkOption {
                  default = "programs";
                  type = coercedTo str lib.singleton (listOf str);
                  description = "Namespace of the program to set impermanence options for.";
                };
                files = lib.mkOption {
                  type = listOf str;
                  default = [ ];
                };
                directories = lib.mkOption {
                  type = listOf str;
                  default = [ ];
                };
              };
            })
          );
        default = { };
        description = "List of nixos programs that need home impermanence options.";
      };

      config = {
        unify.nixos = {
          imports = lib.mapAttrsToList (
            name: cfg:
            mkNixosHomeImpermanenceOption {
              inherit name;
              inherit (cfg) namespace directories files;
            }
          ) config.impermanence.programs.nixos-home;
        };
      };
    };
in
{
  flake.modules.flake.impermanenceNixosHomePrograms = module;
  imports = [ module ];
}
