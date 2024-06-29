{pkgs}: let
  attrsToPaths = attrs: pkgs.lib.mapAttrsToList (name: path: {inherit name path;}) attrs;
  allPlugins = pkgs.lib.filterAttrs (n: v: n != "all") pkgs.sketchybar-plugins;
in {
  builtin = pkgs.callPackage ./builtin.nix {};
  all = pkgs.linkFarm "sketchybar-plugins" (attrsToPaths allPlugins);
}
