{pkgs}: let
  attrsToPaths = attrs: pkgs.lib.mapAttrsToList (name: path: {inherit name path;}) attrs;
  allThemes = pkgs.lib.filterAttrs (n: v: n != "all") pkgs.waybar-themes;
in {
  catppuccin = pkgs.callPackage ./catppuccin.nix {};
  all = pkgs.linkFarm "waybar-themes" (attrsToPaths allThemes);
}
