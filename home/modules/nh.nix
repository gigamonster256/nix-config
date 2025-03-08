{
  inputs,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
  nh-pkg =
    if isDarwin
    then inputs.nh.packages.${pkgs.stdenv.hostPlatform.system}.default
    else pkgs.nh;
in {
  home.packages = [
    nh-pkg
  ];
  home.sessionVariables.NH_FLAKE = "github:gigamonster256/nix-config";
}
