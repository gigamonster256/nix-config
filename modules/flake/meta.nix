let
  module =
    { lib, ... }:
    {
      options.meta = {
        owner = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Name of the owner of this configuration.";
          };
          email = lib.mkOption {
            type = lib.types.str;
            description = "Email of the owner of this configuration.";
          };
        };

        flake = lib.mkOption {
          type = lib.types.str;
          description = "URL of the flake repository.";
        };
      };
    };
in
{
  # import the module to use it internally
  imports = [ module ];
  # export the module for use in other flake modules
  flake.modules.flake.meta = module;
}
