# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs}: let
  attrsToPaths = attrs: pkgs.lib.mapAttrsToList (name: path: {inherit name path;}) attrs;
  withAllFarm = name: pkgs': pkgs' // {all = pkgs.linkFarm name (attrsToPaths pkgs');};
  withAllFlat = name: pkgs':
    pkgs'
    // {
      all = pkgs.symlinkJoin {
        inherit name;
        paths = pkgs.lib.attrValues pkgs';
      };
    };
in rec {
  # themes avilable in $out/share/sddm/themes/<package-name>
  sddm-themes = withAllFlat "sddm-themes" (import ./sddm-themes {inherit pkgs;});
  # themes available in $out/share/btop/themes/<theme-name>.theme
  btop-themes = withAllFlat "btop-themes" (import ./btop-themes {inherit pkgs;});
  # plugins available in $out/<package-name>/<plugin-name>.sh using all
  sketchybar-plugins = withAllFarm "sketchybar-plugins" (import ./sketchybar-plugins {inherit pkgs;});
  # themes available in $out/<package-name>/<theme-name>.css using all
  waybar-themes = withAllFarm "waybar-themes" (import ./waybar-themes {inherit pkgs;});
  # trilium-next-desktop = pkgs.callPackage ./trilium-next/from-source.nix {};
  trilium-next-desktop = (import ./trilium-next/prebuilt.nix {inherit pkgs;}).trilium-next;
  inherit
    (pkgs.callPackage ./electron {})
    electron_31-bin
    ;
  electron_31 = electron_31-bin;
}
