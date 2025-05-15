{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  programs.jujutsu.settings = {
    user = {
      name = mkDefault config.programs.git.userName;
      email = mkDefault config.programs.git.userEmail;
    };
    ui = {
      merge-editor = mkDefault ":builtin";
      default-command = mkDefault [ "log" ];
      pager = mkDefault ":builtin";
    };
  };
}
