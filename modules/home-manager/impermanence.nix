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
    mkAfter
    ;
  cfg = config.impermanence;
in
{
  options = {
    impermanence = {
      enable = mkEnableOption "impermanence" // {
        default = systemConfig.impermanence.enable or false;
      };
      persistPath = mkOption {
        type = types.singleLineStr;
        default = systemConfig.impermanence.persistPath or "/persist";
      };
      directories = mkOption {
        type = with types; listOf anything; # let the impermanence module do the type checking
        default = [ ];
      };
      files = mkOption {
        type = with types; listOf anything; # let the impermanence module do the type checking
        default = [ ];
      };
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = systemConfig != null;
          message = "home-manager impermanence.enable requires a valid system configuration";
        }
      ];
      home.persistence."${cfg.persistPath}" = {
        inherit (cfg) directories files;
      };
    }
    # defaults
    {
      impermanence = {
        directories = mkAfter [
          ".ssh"
          ".gnupg"
          ".local/share/nix"
        ];
        files = mkAfter [ ];
      };
    }
    # programs built into home-manager/nixos
    (mkIf config.programs.firefox.enable {
      impermanence.directories = [ ".mozilla" ];
    })
    (mkIf systemConfig.programs.steam.enable {
      impermanence.directories = [
        ".local/share/Steam"
        ".local/share/applications" # save installed game entries - a little crufty
      ];
    })
    (mkIf systemConfig.programs.alvr.enable {
      impermanence.directories = [
        ".config/alvr"
        ".config/openvr"
      ];
    })
    (mkIf config.programs.direnv.enable {
      impermanence.directories = [ ".local/share/direnv" ];
    })
    (mkIf config.programs.zsh.enable {
      impermanence.files = [ ".zsh_history" ];
    })
    # https://github.com/nix-community/home-manager/blob/master/modules/programs/vscode.nix
    # differs based on which vscode fork is used
    (mkIf config.programs.vscode.enable {
      impermanence.directories = [
        ".config/Code"
        ".vscode"
      ];
    })
    (mkIf config.programs.vesktop.enable {
      impermanence.directories = [ ".config/vesktop" ];
    })
    (mkIf systemConfig.programs.zoom-us.enable {
      impermanence = {
        directories = [ ".zoom" ];
        files = [
          ".config/zoom.conf"
          ".config/zoomus.conf"
        ];
      };
    })
    (mkIf config.programs.nix-index-database.comma.enable {
      impermanence.files = [ ".local/state/comma-choices" ];
    })
  ]);
}
