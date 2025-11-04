let
  shell =
    {
      pkgs ? import <nixpkgs> { },
      ...
    }:
    pkgs.mkShellNoCC {
      NIX_CONFIG = "extra-experimental-features = nix-command flakes ca-derivations";

      nativeBuildInputs = with pkgs; [
        nix
        git

        sops
        ssh-to-age
        gnupg
        age
      ];

      shellHook = ''
        export NH_FLAKE=`git rev-parse --show-toplevel`
      '';
    };
in
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = shell { inherit pkgs; };
    };
}
