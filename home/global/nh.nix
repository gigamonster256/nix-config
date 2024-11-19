{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
  nh-pkg =
    if isDarwin
    then inputs.nh_plus.packages.${pkgs.stdenv.hostPlatform.system}.default
    else pkgs.nh;
in {
  home.packages = [
    nh-pkg
  ];
  # home.sessionVariables.FLAKE = lib.mkDefault "github:gigamonster256/nix-config";
  home.sessionVariables.FLAKE = "${config.home.homeDirectory}/projects/nix-config";
}
