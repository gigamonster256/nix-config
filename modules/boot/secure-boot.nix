{ inputs, ... }:
{
  unify.modules.secure-boot.nixos =
    { lib, config, ... }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];
      boot = {
        # Override systemd-boot when using lanzaboote
        loader.systemd-boot.enable = lib.mkOverride 750 (!config.boot.lanzaboote.enable);
        lanzaboote = {
          enable = lib.mkDefault true;
          pkiBundle = lib.mkDefault "/var/lib/sbctl";
        };
      };
    };

  # TODO: use impermanence.programs.nixos option somehow
  # some sort of overriden condition to make sure lanzaboote is imported first?
  unify.modules.impermanence.nixos =
    { lib, config, ... }:
    lib.mkIf (config.boot ? lanzaboote && config.boot.lanzaboote.enable) {
      impermanence.directories = [ config.boot.lanzaboote.pkiBundle ];
    };
}
