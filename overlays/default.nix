# This file defines overlays
{ inputs, ... }:
let
  customPkgs = pkgs: import ../pkgs { inherit pkgs; };
in
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: customPkgs final;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: _prev: {
    # custom trilium-next-desktop package
    # trilium-desktop = (customPkgs final).trilium-next-desktop;
  };

  # # induced by https://github.com/NixOS/nixpkgs/pull/385341 and backports to 24.11
  # # using the --unpack hash
  # electron_shananagains = final: prev: {
  #   electron_35 = prev.electron_35.overrideAttrs (oldAttrs: {
  #     passthru.headers =
  #       let
  #         headersFetcher =
  #           vers: hash:
  #           final.fetchurl {
  #             url = "https://artifacts.electronjs.org/headers/dist/v${vers}/node-v${vers}-headers.tar.gz";
  #             sha256 = hash;
  #           };
  #       in
  #       # nix-prefetch-url url (not using --unpack)
  #       headersFetcher oldAttrs.version "19b6amp8cqhgmif5rmgi7vayyr8m7mh8b179s3f4azxyzfis192z";
  #   });
  # };

  # # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # # be accessible through 'pkgs.unstable'
  # unstable-packages = final: _prev: {
  #   unstable = import inputs.nixpkgs-unstable {
  #     inherit (final) system;
  #     config.allowUnfree = true;
  #   };
  # };

  mac-ghostty-from-nur = final: prev: {
    ghostty =
      if final.stdenv.hostPlatform.isDarwin then
        final.nur.repos.gigamonster256.ghostty-darwin
      else
        prev.ghostty;
  };
}
