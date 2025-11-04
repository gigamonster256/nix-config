{
  unify.home =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib)
        mkDefault
        mkIf
        getExe
        ;
      cfg = config.programs.oh-my-posh;
    in
    {
      programs.oh-my-posh = {
        enable = mkDefault config.programs.zsh.enable;
      };

      programs.zsh.initContent = mkIf cfg.enable ''
        # disable auto update notice
        ${getExe cfg.package} disable notice
      '';
    };
}
