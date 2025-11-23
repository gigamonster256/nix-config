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

  # create the impermanence options for lanzaboote
  impermanence.programs.nixos = {
    lanzaboote = {
      namespace = "boot";
    };
  };

  # add the lanzaboote pkiBundle to the impermanence dirs
  unify.modules.impermanence.nixos =
    { lib, config, ... }:
    {
      boot.lanzaboote.impermanence.directories = lib.mkIf (
        config.boot ? lanzaboote && config.boot.lanzaboote.enable
      ) [ config.boot.lanzaboote.pkiBundle ];
    };
}
