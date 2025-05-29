{
  lib,
  config,
  ...
}:
{
  options = {
    impermanence = {
      enable = lib.mkEnableOption "impermanence";
      persistPath = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "/persist";
      };
      userPath = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "/home/${config.home.username}";
      };
    };
  };
  config =
    let
      cfg = config.impermanence;
    in
    lib.mkIf cfg.enable {
      home.persistence."${cfg.persistPath}/${cfg.userPath}" = {
        # allowOther = true;
        directories = [
          {
            directory = ".local/share/Steam";
            method = "symlink";
          }
          ".ssh"
          ".config/spotify"
          ".gnupg"
        ];
        files = [ ];
      };
    };
}
