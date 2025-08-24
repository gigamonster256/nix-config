{ lib, config, ... }:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    ./wireless.nix
    ./vpn.nix
    ./hyprland.nix
    ./sudo.nix
    ./sops.nix
    ./nixos.nix
    ./fingerprint.nix
    ./stylix.nix
    ./sddm.nix
    ./keyring.nix
  ];

  home-manager.backupFileExtension = mkDefault "backup";
  services.blueman.enable = mkDefault config.hardware.bluetooth.enable;
  # TODO: fix this up
  networking.useNetworkd = true; # https://github.com/nix-community/nixos-facter-modules/issues/83
}
