# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs}: {
  sddm-themes = import ./sddm-themes {inherit pkgs;};
  btop-themes = import ./btop-themes {inherit pkgs;};
  sketchybar-plugins = import ./sketchybar-plugins {inherit pkgs;};
  waybar-themes = import ./waybar-themes {inherit pkgs;};
}
