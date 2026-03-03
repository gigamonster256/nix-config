let
  module =
    { lib, ... }:
    {
      options = {
        packages = lib.mkOption {
          type = lib.types.attrsOf (lib.types.functionTo lib.types.package);
          default = { };
          description = ''
            This option allows modules to define custom packages
            that will be made available in the 'packages' output
            of this flake.
          '';
        };
        # not sure how useful this is since the args can't pull in any of nixpkgs
        packageArgs = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
          default = { };
          example = {
            sowon.withPenger = false;
          };
          description = ''
            This option allows modules to define custom arguments
            that will be passed to the callPackage functions when
            building the packages defined in the 'packages' option.
          '';
        };
      };
    };
in
{ config, ... }:
{
  # import the module to use it internally
  imports = [ module ];
  # export the module for use in other flake modules
  flake.modules.flake.packages = module;

  # render the packages defined in config.packages
  perSystem =
    { pkgs, ... }:
    {
      # instead of re-evaluating the packages here, we can just grab them from the
      # flake overlaid packages
      packages = builtins.intersectAttrs config.packages pkgs;
    };

  flake.overlays = {
    # Overlay to add the packages defined in config.packages
    additions =
      final: _prev:
      builtins.mapAttrs (
        name: pkg: final.callPackage pkg config.packageArgs.${name} or { }
      ) config.packages;
  };
}
