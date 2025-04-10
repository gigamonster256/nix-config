{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.jujutsu = let
    inherit (lib) mkDefault;
  in {
    package = mkDefault pkgs.unstable.jujutsu;
    settings = {
      user = {
        name = mkDefault config.programs.git.userName;
        email = mkDefault config.programs.git.userEmail;
      };
      ui = {
        merge-editor = mkDefault ":builtin";
        default-command = mkDefault ["log"];
        pager = mkDefault ":builtin";
      };
    };
  };
}
