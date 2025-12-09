{
  nixpkgs.allowedUnfreePackages = [
    "vscode"
  ];

  unify.modules.dev.home = {
    programs.vscode.enable = true;
    programs.vscode.profiles.default.userSettings = {
      "files.autoSave" = "afterDelay";
      "terminal.integrated.fontFamily" = "Monaspace Neon";
      "terminal.integrated.suggest.enabled" = false;
      "terminal.integrated.suggest.inlineSuggestion" = "off";
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
