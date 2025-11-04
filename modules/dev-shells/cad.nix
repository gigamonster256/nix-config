let
  shell =
    {
      pkgs ? import <nixpkgs> { },
    }:
    pkgs.mkShellNoCC {
      packages = builtins.attrValues {
        inherit (pkgs)
          freecad
          prusa-slicer
          # cura
          ;
      };
    };
in
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.cad = shell { inherit pkgs; };
    };
}
