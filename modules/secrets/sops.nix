{ inputs, config, ... }:
{
  # globally import sops nixos module
  flake.modules.nixos.default = {
    imports = [
      config.flake.modules.nixos.secrets
    ];
  };

  flake.modules.nixos.secrets =
    { lib, config, ... }:
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops = {
        defaultSopsFile = lib.mkDefault ../../hosts/${config.networking.hostName}/secrets.yaml;
        age = {
          sshKeyPaths = lib.mkDefault [
            "/etc/ssh/ssh_host_ed25519_key"
          ];
          generateKey = lib.mkDefault false;
        };
      };
    };

  flake.modules.homeManager.secrets =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.homeModules.sops ];
      sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    };
}
