{ inputs, persistence-lib, ... }:
{
  # create the impermanence options for lanzaboote
  # NOTE: since boot.lanzaboote doesnt exist without importing secure-boot,
  # uts a little cleaner to put this in the secure-boot module as mkPersistenceModule
  # persistence.programs.nixos = {
  #   lanzaboote = {
  #     namespace = "boot";
  #   };
  # };

  unify.modules.secure-boot.nixos =
    { lib, config, ... }:
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
        # only create the persistence module if impermanence is enabled
        (persistence-lib.mkPersistenceModule {
          name = "lanzaboote";
          namespace = [ "boot" ];
          configFn = persistence-lib.defaultNixosPersistenceConfigFn;
        })
      ];
      boot = {
        # Override systemd-boot when using lanzaboote
        loader.systemd-boot.enable = lib.mkOverride 750 (!config.boot.lanzaboote.enable);
        lanzaboote = {
          enable = lib.mkDefault true;
          pkiBundle = lib.mkDefault "/var/lib/sbctl";
        };
      };
    };

  # add the lanzaboote pkiBundle to the impermanence dirs
  unify.modules.impermanence.nixos =
    { lib, config, ... }:
    lib.mkIf (config.boot ? lanzaboote) {
      boot.lanzaboote.persistence.directories = [
        config.boot.lanzaboote.pkiBundle
      ];
    };
}
