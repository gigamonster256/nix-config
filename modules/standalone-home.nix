{ config, ... }:
{
  configurations.home = {
    # just my global config plus dev for linux
    chnorton = {
      system = "x86_64-linux";
      module = {
        imports = [ config.unify.modules.dev.home ];
      };
    };
  };
}
