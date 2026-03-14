{
  flake.modules.nixos.laptop =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.brightnessctl
      ];
    };
}
