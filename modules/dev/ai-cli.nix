{ inputs, moduleWithSystem, ... }:
{
  # TODO: use an overlay rather than moduleWithSystem?
  unify.modules.dev.home = moduleWithSystem (
    { system, ... }:
    { lib, ... }:
    {
      # home.packages = [
      #   # lets try out desktop version
      #   inputs.opencode.packages.${system}.desktop
      # ];
      programs.opencode = {
        enable = lib.mkDefault true;
        package = inputs.opencode.packages.${system}.desktop; # desktop version inclides cli as "opencode-cli"
      };
      # programs.gemini-cli.enable = lib.mkDefault true;
    }
  );

  persistence.programs.homeManager = {
    opencode = {
      directories = [ ".local/share/opencode" ];
    };
    gemini-cli = {
      directories = [ ".gemini" ];
    };
  };
}
