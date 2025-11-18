{
  home-manager.extraPrograms = [
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

  impermanence.programs.home = {
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
