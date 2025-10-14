{ lib, ... }:
{
  unify.modules.dev.home = {
    programs.opencode.enable = lib.mkDefault true;
    programs.gemini-cli.enable = lib.mkDefault true;
  };
}
