# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs ? import <nixpkgs> {}}: let
  attrsToPaths = attrs: pkgs.lib.mapAttrsToList (name: path: {inherit name path;}) attrs;
  withAllFarm = name: drvs: drvs // {all = pkgs.linkFarm name (attrsToPaths drvs);};
  withAllFlat = name: drvs:
    drvs
    // {
      all = pkgs.symlinkJoin {
        inherit name;
        paths = pkgs.lib.attrValues drvs;
      };
    };
in rec {
  # themes avilable in $out/share/sddm/themes/<package-name>
  sddm-themes = withAllFlat "sddm-themes" (import ./sddm-themes {inherit pkgs;});
  # themes available in $out/share/btop/themes/<theme-name>.theme
  btop-themes = withAllFlat "btop-themes" (import ./btop-themes {inherit pkgs;});
  # themes available in $out/share/eza/themes/<theme-name>
  eza-themes = withAllFlat "eza-themes" (import ./eza-themes {inherit pkgs;});
  # plugins available in $out/<package-name>/<plugin-name>.sh using all
  sketchybar-plugins = withAllFarm "sketchybar-plugins" (import ./sketchybar-plugins {inherit pkgs;});
  # themes available in $out/<package-name>/<theme-name>.css using all
  waybar-themes = withAllFarm "waybar-themes" (import ./waybar-themes {inherit pkgs;});
  # trilium-next-desktop = pkgs.callPackage ./trilium-next/from-source.nix {};
  trilium-next-desktop = (import ./trilium-next/prebuilt.nix {inherit pkgs;}).trilium-next;
  fv = pkgs.callPackage ./fv.nix {};
  flash = pkgs.callPackage ./flash.nix {};
  extract = pkgs.callPackage ./extract.nix {};
}
