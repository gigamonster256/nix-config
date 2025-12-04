{
  persistence.wrappers.homeManager = [
    "cemu"
    {
      name = "ryujinx";
      packageName = "ryubing";
    }
    "wiiu-downloader"
  ];

  unify.modules.emulators.home = {
    programs.cemu.enable = true;
    programs.ryujinx.enable = true;
    programs.wiiu-downloader.enable = true;
  };

  persistence.programs.homeManager = {
    cemu = {
      directories = [
        ".config/Cemu"
        ".local/share/Cemu"
        ".cache/Cemu"
      ];
    };
    ryujinx = {
      directories = [ ".config/Ryujinx" ];
    };
    wiiu-downloader = {
      directories = [ ".config/WiiUDownloader" ];
    };
  };
}
