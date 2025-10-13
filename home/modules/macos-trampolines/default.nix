{
  flake.modules.homeManager.base =
    { lib, pkgs, ... }:
    {
      home.activation.makeTrampolineApps = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
        lib.hm.dag.entryAfter [ "writeBoundary" ] (builtins.readFile ./make-app-trampolines.sh)
      );
    };
}
