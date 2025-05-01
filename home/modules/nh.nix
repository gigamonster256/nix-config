{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.nh = {
    # nh 4.0 is in unstable
    package = mkDefault pkgs.unstable.nh;
    # TODO: wait for home-manager/#6468 to land in my home-manager channel
    # flake = mkDefault "github:gigamonster256/nix-config";
  };
  # TODO: the beta changes the session variable name to NH_FLAKE
  home.sessionVariables.NH_FLAKE = lib.mkIf config.programs.nh.enable (mkDefault "github:gigamonster256/nix-config");
}
