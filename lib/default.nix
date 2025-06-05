{
  mkPersistentProgram =
    {
      name,
      defaultEnable ? false,
      packageName ? name,
      packageOptions ? { },
      directories ? [ ],
      files ? [ ],
    }:
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib) mkIf mkEnableOption mkPackageOption;
      cfg = config.programs.${name};
    in
    {
      options = {
        programs.${name} = {
          enable = mkEnableOption name // {
            default = defaultEnable;
          };
          package = mkPackageOption pkgs packageName packageOptions;
        };
      };

      config = mkIf cfg.enable {
        home.packages = [ cfg.package ];
        impermanence = {
          inherit directories files;
        };
      };
    };
}
