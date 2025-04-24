# This file defines overlays
{inputs, ...}: let
  customPkgs = pkgs: import ../pkgs {inherit pkgs;};
in {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: customPkgs final;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: _prev: {
    # custom trilium-next-desktop package
    # trilium-desktop = (customPkgs final).trilium-next-desktop;
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
}
