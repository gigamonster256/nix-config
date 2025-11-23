let
  mkImpermanenceModule =
    {
      optionPath,
      unifyPath,
      configFn,
      description,
    }:
    { lib, config, ... }:
    let
      mkOptionModule =
        {
          programName,
          namespace,
          directories,
          files,
        }:
        { lib, config, ... }:
        let
          path = lib.splitString "." programName;
          programPath = namespace ++ path;
          impermanencePath = programPath ++ [ "impermanence" ];
          getVal = p: default: lib.attrByPath p default config;
          impermanenceCfg = getVal impermanencePath { };
        in
        {
          options = lib.setAttrByPath impermanencePath {
            enable = (lib.mkEnableOption ("impermanence for " + programName)) // {
              default = getVal (programPath ++ [ "enable" ]) false;
            };
            directories = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = directories;
              description = "List of directories to persist for ${programName}.";
            };
            files = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = files;
              description = "List of files to persist for ${programName}.";
            };
          };
          config = lib.mkIf (impermanenceCfg.enable or false) (configFn impermanenceCfg);
        };
    in
    {
      options = lib.setAttrByPath optionPath (
        lib.mkOption {
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
          inherit description;
        }
      );

      config = lib.setAttrByPath unifyPath {
        imports = lib.mapAttrsToList (
          programName: cfg:
          mkOptionModule {
            inherit programName;
            inherit (cfg) namespace directories files;
          }
        ) (lib.attrByPath optionPath { } config);
      };
    };

  homeModule = mkImpermanenceModule {
    optionPath = [
      "impermanence"
      "programs"
      "home"
    ];
    unifyPath = [
      "unify"
      "modules"
      "impermanence"
      "home"
    ];
    configFn = cfg: {
      impermanence = {
        inherit (cfg) directories files;
      };
    };
    description = "List of home programs to set impermanence options for.";
  };

  nixosModule = mkImpermanenceModule {
    optionPath = [
      "impermanence"
      "programs"
      "nixos"
    ];
    unifyPath = [
      "unify"
      "modules"
      "impermanence"
      "nixos"
    ];
    configFn = cfg: {
      impermanence = {
        inherit (cfg) directories files;
      };
    };
    description = "List of nixos programs to set impermanence options for.";
  };

  nixosHomeModule = mkImpermanenceModule {
    optionPath = [
      "impermanence"
      "programs"
      "nixos-home"
    ];
    unifyPath = [
      "unify"
      "modules"
      "impermanence"
      "nixos"
    ];
    configFn = cfg: {
      home-manager.sharedModules = [
        {
          impermanence = {
            inherit (cfg) directories files;
          };
        }
      ];
    };
    description = "List of nixos programs that need home impermanence options.";
  };
in
{
  flake.modules.flake = {
    homeProgramImpermenence = homeModule;
    nixosProgramImpermenence = nixosModule;
    nixosHomeProgramImpermenence = nixosHomeModule;
  };
  imports = [
    homeModule
    nixosModule
    nixosHomeModule
  ];
}
