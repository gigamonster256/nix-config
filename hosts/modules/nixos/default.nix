{lib, ...}: {
  imports = [
    ./wireless.nix
    ./hyprland.nix
    ./sudo.nix
  ];

  home-manager.backupFileExtension = lib.mkDefault "backup";
}
