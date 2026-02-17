{
  unify.home =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.programs.oh-my-posh;
    in
    {
      programs.oh-my-posh = {
        enable = lib.mkDefault config.programs.zsh.enable;
      };

      programs.zsh.initContent = lib.mkIf cfg.enable ''
        # disable auto update notice
        ${lib.getExe cfg.package} disable notice
      '';
    };
}
