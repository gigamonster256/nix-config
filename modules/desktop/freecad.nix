{
  persistence.wrappers.homeManager = [ "freecad" ];

  persistence.programs.homeManager = {
    freecad = {
      directories = [
        ".config/FreeCAD"
        ".local/share/FreeCAD"
      ];
    };
  };
}
