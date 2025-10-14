{
  flake.modules.homeManager.base =
    { lib, config, ... }:
    {
      programs.jujutsu.settings = {
        user = {
          name = lib.mkDefault config.programs.git.userName;
          email = lib.mkDefault config.programs.git.userEmail;
        };
        ui = {
          merge-editor = lib.mkDefault ":builtin";
          diff-editor = lib.mkDefault ":builtin";
          default-command = lib.mkDefault [ "log" ];
          pager = lib.mkDefault ":builtin";
        };
        signing = {
          behavior = "keep";
          backend = "gpg";
        };
      };
    };
}
