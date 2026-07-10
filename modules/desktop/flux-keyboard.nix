{
  flake.modules.nixos.default =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.programs.polymath;
    in
    lib.mkIf cfg.enable {
      services.udev.packages = [ cfg.package ];
    };

  persistence.wrappers.nixos = [
    "polymath"
  ];

  # TODO: add persistence dirs once my flux keyboard comes in
}
