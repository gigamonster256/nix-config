{
  inputs,
  pkgs,
  lib,
  ...
}: {
  programs.nh = let
    inherit (pkgs) stdenv writeShellApplication;
    # wrap nh in a function that turns "nh os" into "nh darwin"
    package =
      if stdenv.hostPlatform.isDarwin
      then
        writeShellApplication {
          name = "nh";
          runtimeInputs = [inputs.nh.packages.${stdenv.hostPlatform.system}.default];
          text = ''
            if [[ "$1" == "os" ]]; then
              shift
              set -- darwin "$@"
            fi
            nh "$@"
          '';
        }
      else inputs.nh.packages.${stdenv.hostPlatform.system}.default;
  in {
    enable = true;
    # use nh beta - adds darwin support and repl helpers
    inherit package;
    # TODO: wait for home-manager/#6468 to land in my home-manager channel
    # flake = "github:gigamonster256/nix-config";
  };
  # TODO: the beta changes the session variable name to NH_FLAKE
  home.sessionVariables.NH_FLAKE = "github:gigamonster256/nix-config";
}
