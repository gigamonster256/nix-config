{ inputs, config, ... }:
let
  flakeConfig = config;
in
{
  imports = [
    inputs.persistence.flakeModules.default
    inputs.persistence.flakeModules.programModules
  ];

  flake.modules.nixos.default = {
    imports = [
      inputs.persistence.nixosModules.default
      config.persistence.modules.nixos.wrappedPrograms
    ];
    # FIXME: nix flake check has issues when impermanence is diabled
    #   persistence.homeManagerIntegration.enable = false;
  };
  flake.modules.homeManager.default = {
    imports = [
      # inputs.persistence.homeManagerModules.default # automatically included by integration
      config.persistence.modules.homeManager.wrappedPrograms
    ];
  };

  flake.modules.homeManager.standalone = {
    imports = [
      # allow setting persistence.* options (but dont do anything with them)
      inputs.persistence.homeManagerModules.default
    ];
  };

  flake.modules = {
    nixos.impermanence =
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

    homeManager.impermanence = {
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
