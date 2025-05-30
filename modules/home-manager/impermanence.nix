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
    mkIf
    mkDefault
    optional
    ;
in
{
  options = {
    impermanence = {
      enable = mkEnableOption "impermanence";
      persistPath = mkOption {
        type = types.singleLineStr;
        default = systemConfig.impermanence.persistPath or "/persist";
      };
      userPath = mkOption {
        type = types.singleLineStr;
        default = config.home.homeDirectory;
      };
      directories = mkOption {
        type = with types; listOf str;
        default = [ ];
      };
      files = mkOption {
        type = with types; listOf str;
        default = [ ];
      };
    };
  };
  config =
    let
      cfg = config.impermanence;
    in
    mkIf cfg.enable {
      home.persistence."${cfg.persistPath}/${cfg.userPath}" = {
        allowOther = true;
        directories =
          cfg.directories
          ++ [
            ".ssh"
            ".gnupg"
            ".local/share/nix"
          ]
          ++ (optional systemConfig.programs.steam.enable {
            directory = ".local/share/Steam";
            method = "symlink";
          })
          ++ (optional config.programs.spicetify.enable ".config/spotify");
        files = cfg.files ++ [ ];
      };
    };
}
