{
  persistence.wrappers.homeManager = [
    "cemu"
    {
      name = "ryujinx";
      packageName = "ryubing";
    }
    "wiiu-downloader"
  ];

  flake.modules.homeManager.emulators = {
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
