let
  config = _: {
    # Used to find the project root
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
    programs.yamlfmt.enable = true;
    programs.statix.enable = true;
    programs.deadnix = {
      enable = true;
      no-underscore = true;
    };
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
