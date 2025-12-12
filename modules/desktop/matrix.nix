{
  nixpkgs.permittedInsecurePackages = [
    # "olm-3.2.16" # nheko
  ];

  unify.modules.desktop = {
    home = {
      # TODO: element-desktop is available now in upstream - use its settings
      # also find a good non electron matrix client... 850MB is too much
      programs.element-desktop.enable = true;
      #   programs.nheko.enable = true;
    };
  };

  persistence.programs.homeManager = {
    element-desktop = {
      directories = [
        ".config/Element"
      ];
    };
    nheko = {
      directories = [
        ".config/nheko"
        ".local/share/nheko"
      ];
    };
  };
}
