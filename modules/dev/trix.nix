{ inputs, ... }:
{
  # add trix to pkgs
  nixpkgs.overlays = [ inputs.trix.overlays.default ];
  unify.modules.trix.home =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.trix
      ];

      # add "use trix" syntax to direnv
      programs.direnv.stdlib = "source ${pkgs.trix}/share/trix/direnvrc";
    };
}
