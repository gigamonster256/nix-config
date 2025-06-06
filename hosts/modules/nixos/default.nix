{ lib, config, ... }:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    ./wireless.nix
    ./openconnect.nix
    ./hyprland.nix
    ./sudo.nix
    ./sops.nix
    ./nixos.nix
  ];

  home-manager.backupFileExtension = mkDefault "backup";
  services.blueman.enable = mkDefault config.hardware.bluetooth.enable;
}
