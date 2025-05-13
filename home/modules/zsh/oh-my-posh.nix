{
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    mkDefault
    mkIf
    getExe
    ;
in {
  programs.oh-my-posh = {
    enable = mkDefault config.programs.zsh.enable;
    settings = mkDefault (import ./posh-config.nix);
  };

  programs.zsh.initExtra = let
    cfg = config.programs.oh-my-posh;
  in
    mkIf cfg.enable ''
      # disable auto update notice
      ${getExe cfg.package} disable notice
    '';
}
