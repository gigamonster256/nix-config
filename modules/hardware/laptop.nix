{
  flake.modules.nixos.laptop =
    {
      lib,
      ...
    }:
    {
      services.automatic-timezoned.enable = lib.mkDefault true;
    };
}
