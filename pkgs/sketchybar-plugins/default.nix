{pkgs}: rec {
  builtin = pkgs.callPackage ./builtin.nix {};
  all = pkgs.symlinkJoin {
    name = "sketchybar-plugins";
    paths = [
      builtin
    ];
  };
}
