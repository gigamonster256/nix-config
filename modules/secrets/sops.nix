{ inputs, config, ... }:
{
  # globally import sops nixos module
  unify.nixos = {
    imports = [
      config.unify.modules.secrets.nixos
    ];
  };

  unify.modules.secrets.nixos =
    { lib, ... }:
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops.age = {
        sshKeyPaths = lib.mkDefault [
          "/etc/ssh/ssh_host_ed25519_key"
        ];
        generateKey = lib.mkDefault false;
      };
    };

  unify.modules.secrets.home =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.homeModules.sops ];
      sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    };
}
