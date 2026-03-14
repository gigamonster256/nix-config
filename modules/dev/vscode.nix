{
  nixpkgs.allowedUnfreePackages = [
    "vscode"
  ];

  flake.modules.homeManager.dev =
    { lib, osConfig, ... }:
    {
      programs.vscode = {
        enable = true;
        argvSettings = {
          enable-crash-reporter = false;
          password-store = lib.mkIf (
            osConfig != null && osConfig.services.gnome.gnome-keyring.enable
          ) "gnome-libsecret";
        };
        profiles.default = {
          enableUpdateCheck = false;
          userSettings = {
            "telemetry.telemetryLevel" = "off";
            "telemetry.enableTelemetry" = false;
            "telemetry.enableCrashreporter" = false;

            "files.autoSave" = "afterDelay";

            "terminal.integrated.fontFamily" = "Monaspace Neon";
            "terminal.integrated.suggest.enabled" = false;
            "terminal.integrated.suggest.inlineSuggestion" = "off";
          };
        };
      };
    };

  persistence.programs.homeManager = {
    vscode = {
      # https://github.com/nix-community/home-manager/blob/master/modules/programs/vscode.nix
      # differs based on which vscode fork is used
      directories = [
        ".config/Code"
        ".vscode"
      ];
    };
  };
}
