let
  module =
    { lib, ... }:
    let
      inherit (lib) types;
    in
    {
      options.meta = {
        owner = {
          name = lib.mkOption {
            type = types.str;
            description = "Name of the owner of this configuration.";
          };
          email = lib.mkOption {
            type = types.singleLineStr;
            description = "Email of the owner of this configuration.";
          };
          sshKeys = lib.mkOption {
            type = types.listOf types.singleLineStr;
            description = "List of ssh keys";
          };
        };

        flake = lib.mkOption {
          type = types.str;
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
