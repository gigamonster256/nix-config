{
  packages.sketchybar-plugins =
    {
      linkFarm,
      sketchybar-default-plugins,
      sketchybar-aerospace,
    }:
    (linkFarm "sketchybar-plugins" [
      {
        name = "builtin";
        path = sketchybar-default-plugins;
      }
      {
        name = "aerospace.sh";
        path = sketchybar-aerospace;
      }
    ]);
}
