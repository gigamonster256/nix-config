{
  unify.modules.dev.home =
    { lib, ... }:
    {
      programs.opencode.enable = lib.mkDefault true;
      programs.gemini-cli.enable = lib.mkDefault true;
    };

  impermanence.programs.home = {
    opencode = {
      directories = [ ".local/share/opencode" ];
    };
    gemini-cli = {
      directories = [ ".gemini" ];
    };
  };
}
