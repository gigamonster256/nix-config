{
  flake.modules.homeManager.default = { pkgs, ... }: {
    programs.libreoffice.package = pkgs.libreoffice-fresh;
  };

  persistence.programs.homeManager = {
    libreoffice = {
      directories = [
        ".config/libreoffice"
        # ".local/share/libreoffice"
      ];
    };
  };
}
