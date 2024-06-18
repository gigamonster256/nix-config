{
  inputs,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge;
  inherit (pkgs.stdenv) isDarwin;
in
  mkMerge [
    {
      programs.nh = {
        enable = true;
        flake = "/home/caleb/projects/nix-config";
      };
    }
    (mkIf isDarwin {
      programs.nh.package = inputs.nh-darwin.packages.${pkgs.stdenv.hostPlatform.system}.default;
      environment.shellAliases.nh = "nh-darwin";
    })
  ]
