{
  perSystem =
    { self', pkgs, ... }:
    {
      packages.sketchybar-plugins = pkgs.linkFarm "sketchybar-plugins" [
        {
          name = "builtin";
          path = self'.packages.sketchybar-default-plugins;
        }
        {
          name = "aerospace.sh";
          path = self'.packages.sketchybar-aerospace;
        }
      ];
    };
}
