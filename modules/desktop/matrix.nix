{
  unify.modules.desktop = {
    home = {
      programs.element.enable = true;
    };
  };

  persistence.wrappers.homeManager = [
    {
      name = "element";
      packageName = "element-desktop";
    }
  ];

  persistence.programs.homeManager = {
    element = {
      directories = [ ".config/Element" ];
    };
  };
}
