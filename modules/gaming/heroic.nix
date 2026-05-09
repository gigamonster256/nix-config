{
  flake.modules = {
    nixos.gaming = {
      # GTA Online
      # https://steamcommunity.com/sharedfiles/filedetails/?id=3658540317
      networking.hosts = {
        "0.0.0.0" = [
          "paradise-s1.battleye.com"
          "test-s1.battleye.com"
          "paradiseenhanced-s1.battleye.com"
        ];
      };
    };
    homeManager.gaming = {
      programs.heroic.enable = true;
    };
  };

  persistence.wrappers.homeManager = [
    "heroic"
  ];

  persistence.programs.homeManager = {
    heroic = {
      directories = [
        ".config/heroic"
        ".local/state/Heroic"
        ".games" # generic games install location
      ];
    };
  };
}
