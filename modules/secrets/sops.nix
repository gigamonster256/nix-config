{ inputs, ... }:
{
  flake.modules.nixos.base =
    { lib, config, ... }:
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops.age = {
        sshKeyPaths = lib.mkDefault [
          "/persist/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key"
        ];
        generateKey = lib.mkDefault false;
      };
    };

  flake.modules.homeManager.base =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.homeModules.sops ];
      sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    };
}
