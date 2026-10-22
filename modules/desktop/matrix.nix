{
  nixpkgs.permittedInsecurePackages = [
    # "olm-3.2.16" # nheko
  ];

  flake.modules = {
    homeManager.desktop = { lib, ... }: {
      # find a good non electron matrix client... 850MB is too much
      programs.element-desktop.enable = lib.mkDefault true;
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
