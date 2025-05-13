{ lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  programs.git = {
    userName = mkDefault "Caleb Norton";
    userEmail = mkDefault "n0603919@outlook.com";
    aliases = {
      exec = mkDefault "!exec ";
    };
  };
}
