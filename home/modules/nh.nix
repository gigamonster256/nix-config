{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkDefault;
  cfg = config.programs.nh;
in
{
  programs.nh.flake = mkDefault "github:gigamonster256/nix-config";
}
