{lib, ...}: {
  programs.waybar.settings.mainBar = lib.mkDefault (import ./waybar.nix);
}
