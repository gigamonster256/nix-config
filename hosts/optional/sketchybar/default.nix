{
  config,
  pkgs,
  ...
}: {
  services.sketchybar = {
    enable = true;
    config = import ./config.nix {
      inherit config pkgs;
    };
  };
  fonts.packages = [
    pkgs.sketchybar-app-font
  ];
}
