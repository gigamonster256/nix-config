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
        # TODO: add aditional args for the callPackage functions?
      };
    };
in
{ config, ... }:
let
  # TODO: use actual callPackagesWith function from nixpkgs
  callPackagesWith = pkgs: builtins.mapAttrs (_name: fn: pkgs.callPackage fn { }) config.packages;
in
{
  # import the module to use it internally
  imports = [ module ];
  # export the module for use in other flake modules
  flake.modules.flake.packages = module;

  # render the packages defined in config.packages to my flake outputs
  perSystem =
    { pkgs, ... }:
    {
      packages = callPackagesWith pkgs;
    };

  flake.overlays = {
    # Overlay to add the packages defined in config.packages
    additions = final: _prev: callPackagesWith final;
  };
}
