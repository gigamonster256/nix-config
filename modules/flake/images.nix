{ lib, ... }:
{
  options = {
    flake.images = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      description = "Custom images provided by this flake.";
    };
  };
}
