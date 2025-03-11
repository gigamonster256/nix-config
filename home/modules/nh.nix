{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.nh.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  home.sessionVariables.NH_FLAKE = "github:gigamonster256/nix-config";
}
