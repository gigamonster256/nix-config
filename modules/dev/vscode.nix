{
  nixpkgs.allowedUnfreePackages = [
    "vscode"
  ];

  unify.modules.dev.home = {
    programs.vscode.enable = true;
    programs.vscode.profiles.default.userSettings = {
      "files.autoSave" = "afterDelay";
      "terminal.integrated.fontFamily" = "Monaspace Neon";
    };
  };

  impermanence.programs.home = {
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
