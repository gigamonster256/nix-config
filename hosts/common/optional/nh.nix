{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;
in
  lib.mkMerge [
    {
      programs.nh = {
        enable = true;
        # need to upstream allowing github and registry flakes
        # currently the type is checked to be path or null
        # flake = lib.mkDefault "github:gigamonster256/nix-config";
      };
      environment.variables.FLAKE = lib.mkDefault "github:gigamonster256/nix-config";
    }
    (lib.mkIf isLinux {
      environment.variables.FLAKE = "${config.users.users.caleb.home}/projects/nix-config";
    })
    (lib.mkIf isDarwin {
      programs.nh.package = inputs.nh-darwin.packages.${pkgs.stdenv.hostPlatform.system}.default;
      environment.variables.FLAKE = "${config.users.users.caleb.home}/projects/nix-config";
      environment.shellAliases.nh = "nh-darwin";
    })
  ]
