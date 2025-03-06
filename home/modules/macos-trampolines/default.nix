{
  lib,
  pkgs,
  ...
}: {
  home.activation.makeTrampolineApps = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] (
      import ./make-app-trampolines.nix
    )
  );
}
