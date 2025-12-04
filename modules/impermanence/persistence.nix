{ inputs, config, ... }:
let
  flakeConfig = config;
in
{
  imports = [
    inputs.persistence.flakeModules.default
    inputs.persistence.flakeModules.programModules
  ];

  unify = {
    nixos = {
      imports = [
        inputs.persistence.nixosModules.default
        config.persistence.modules.nixos.wrappedPrograms
      ];
      # FIXME: nix flake check has issues when impermanence is diabled
    #   persistence.homeManagerIntegration.enable = false;
    };
    home = {
      imports = [
        # inputs.persistence.homeManagerModules.default # automatically included by integration
        config.persistence.modules.homeManager.wrappedPrograms
      ];
    };
  };

  unify.modules.impermanence = {
    nixos =
      { config, ... }:
      {
        imports = [
          # modules generated from flake options
          flakeConfig.persistence.modules.nixos.default
          flakeConfig.persistence.modules.nixos.homeManager
        ];
        persistence.enable = true;
        persistence.btrfsWipe.enable = config.fileSystems."/".fsType == "btrfs";
        # some sane defaults for system paths
        persistence = {
          directories = [
            "/var/log"
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
            "/var/lib/systemd/timers"
          ];
          files = [
            "/etc/machine-id"
            "/etc/ssh/ssh_host_ed25519_key"
          ];
        };

      };

    home = {
      imports = [
        config.persistence.modules.homeManager.default
      ];
      # some sane defaults
      persistence = {
        directories = [
          ".ssh"
          ".gnupg"
          ".local/share/nix"
        ];
        # files = [ ];
      };
    };
  };
}
