{
  home-manager.extraPrograms = [
    "slack"
    "sonusmix"
  ];

  impermanence.programs.home = {
    slack = {
      directories = [ ".config/Slack" ];
    };
    sonusmix = {
      directories = [ ".local/share/org.sonusmix.Sonusmix" ];
    };
  };
}
