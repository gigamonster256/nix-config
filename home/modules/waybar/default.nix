{lib, ...}: {
  programs.waybar = {
    settings.mainBar = lib.mkDefault (import ./config.nix);
    style = lib.mkDefault (builtins.readFile ./style.css);
  };
}
