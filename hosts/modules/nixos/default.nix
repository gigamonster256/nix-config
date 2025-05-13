{lib, ...}: {
  imports = [
    ./wireless.nix
    ./hyprland.nix
    ./sudo.nix
    ./sops.nix
  ];

  home-manager.backupFileExtension = lib.mkDefault "backup";
}
