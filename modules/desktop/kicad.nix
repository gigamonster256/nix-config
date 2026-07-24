{
  persistence.wrappers.homeManager = [ "kicad" ];

  persistence.programs.homeManager = {
    kicad = {
      directories = [
        ".config/kicad"
        ".local/share/kicad"
      ];
    };
  };
}
