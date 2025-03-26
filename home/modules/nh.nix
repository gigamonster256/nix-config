{
  inputs,
  pkgs,
  lib,
  ...
}: {
  programs.nh = {
    enable = true;
    # use nh beta - adds darwin support and repl helpers
    package = inputs.nh.packages.${pkgs.stdenv.hostPlatform.system}.default;
    # TODO: wait for home-manager/#6468 to land in my home-manager channel
    # flake = "github:gigamonster256/nix-config";
  };
  # TODO: the beta changes the session variable name to NH_FLAKE
  home.sessionVariables.NH_FLAKE = "github:gigamonster256/nix-config";
}
