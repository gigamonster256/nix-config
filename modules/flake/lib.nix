let
  module =
    { lib, ... }:
    {
      options = {
        lib = lib.mkOption {
          type = lib.types.attrsOf lib.types.attrs;
          default = { };
          description = ''
            This option allows modules to define helper functions,
            constants, etc.
          '';
        };
      };
    };
in
{
  # import the module to use it internally
  imports = [ module ];
  # export the module for use in other flakes
  flake.modules.flake.lib = module;
}
