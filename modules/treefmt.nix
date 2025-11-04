let
  config =
    { pkgs, ... }:
    {
      # Used to find the project root
      projectRootFile = "flake.nix";
      programs.nixfmt.enable = true;
      programs.yamlfmt.enable = true;
    };
in
{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem =
    { pkgs, ... }:
    {
      treefmt = config { inherit pkgs; };
    };

}
