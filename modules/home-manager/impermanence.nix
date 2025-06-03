{
  lib,
  config,
  systemConfig,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkMerge
    mkIf
    mkDefault
    optional
    ;
  cfg = config.impermanence;
in
{
  options = {
    impermanence = {
      enable = mkEnableOption "impermanence" // {
        default = systemConfig.impermanence.enable;
      };
      persistPath = mkOption {
        type = types.singleLineStr;
        default = systemConfig.impermanence.persistPath or "/persist";
      };
      userPath = mkOption {
        type = types.singleLineStr;
        default = config.home.homeDirectory;
      };
      directories = mkOption {
        type = with types; listOf anything; # let the impermanence module do the type checking
        default = [ ];
      };
      files = mkOption {
        type = with types; listOf str;
        default = [ ];
      };
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      home.persistence."${cfg.persistPath}/${cfg.userPath}" = {
        allowOther = true;
        directories = cfg.directories ++ [
          ".ssh"
          ".gnupg"
          ".local/share/nix"
        ];
        files = cfg.files ++ [ ];
      };
    }
    # programs built into home-manager/nixos
    (mkIf config.programs.firefox.enable {
      impermanence.directories = [ ".mozilla" ];
    })
    (mkIf systemConfig.programs.steam.enable {
      impermanence.directories = [
        {
          directory = ".local/share/Steam";
          method = "symlink";
        }
      ];
    })
    (mkIf config.programs.direnv.enable {
      impermanence.directories = [ ".local/share/direnv" ];
    })
    (mkIf config.programs.zsh.enable {
      impermanence.files = [ ".zsh_history" ];
    })
    (mkIf config.programs.vscode.enable {
      impermanence.directories = [ ".vscode" ];
    })
  ]);
}
