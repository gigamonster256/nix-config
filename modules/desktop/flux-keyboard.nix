{
  flake.modules.nixos.flux-keyboard =
    { pkgs, ... }:
    {
      services.udev.packages = [ pkgs.polymath ];
    };

  flake.modules.homeManager.flux-keyboard = _: {
    programs.polymath.enable = true;
  };

  persistence.wrappers.homeManager = [
    "polymath"
  ];
}
