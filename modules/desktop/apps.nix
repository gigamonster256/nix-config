{
  persistence.wrappers.homeManager = [
    "slack"
    "sonusmix"
  ];

  persistence.programs.homeManager = {
    slack = {
      directories = [ ".config/Slack" ];
    };
    sonusmix = {
      directories = [ ".local/share/org.sonusmix.Sonusmix" ];
    };
  };
}
