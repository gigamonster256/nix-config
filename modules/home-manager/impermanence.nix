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
        type = with types; listOf anything; # let the impermanence module do the type checking
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
        directories = cfg.directories ++ [
          ".ssh"
          ".gnupg"
          ".local/share/nix"
        ];
        files = cfg.files ++ [ ];
      };
    };
}
