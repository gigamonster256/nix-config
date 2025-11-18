let
  mkHomeOption =
    { name, packageName }:
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.programs.${name};
    in
    {
      options.programs.${name} = {
        enable = lib.mkEnableOption name;
        package = lib.mkPackageOption pkgs packageName { };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];
      };
    };
  module =
    { lib, config, ... }:
    {
      options.home-manager.extraPrograms = lib.mkOption {
        type =
          with lib.types;
          listOf (
            coercedTo str
              (name: {
                inherit name;
                packageName = name;
              })
              (submodule {
                options = {
                  name = lib.mkOption { type = str; };
                  packageName = lib.mkOption { type = str; };
                };
              })
          );
        default = [ ];
        description = "List of home programs to wrap with package option.";
      };

      config = {
        unify.home = {
          imports = builtins.map mkHomeOption config.home-manager.extraPrograms;
        };
      };
    };
in
{
  flake.modules.flake.homeProgramOptions = module;
  imports = [ module ];
}
