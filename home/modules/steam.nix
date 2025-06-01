{ lib, systemConfig, ... }:
let
  inherit (lib) mkIf;
  cfg = systemConfig.programs.steam;
in
mkIf cfg.enable {
  impermanence.directories = [
    {
      directory = ".local/share/Steam";
      method = "symlink";
    }
  ];
}
