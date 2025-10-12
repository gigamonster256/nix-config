{ lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  boot.loader.systemd-boot.configurationLimit = mkDefault 20;
  system.autoUpgrade = {
    enable = mkDefault true;
    flake = mkDefault "github:gigamonster256/nix-config";
    # hmm this seems a little unsafe
    flags = [ "--accept-flake-config" ];
  };
}
