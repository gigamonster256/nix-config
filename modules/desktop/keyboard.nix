{
  unify.modules.laptop.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.brightnessctl
      ];
    };
}
