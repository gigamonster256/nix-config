{pkgs, ...}: {
  services.sketchybar = {
    enable = true;
    config = import ./config.nix {
      inherit pkgs;
    };
  };
  fonts.packages = with pkgs; [
    sketchybar-app-font
  ];
}
