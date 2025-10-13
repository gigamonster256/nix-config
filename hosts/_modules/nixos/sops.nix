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
          "${
            let
              cfg = config.impermanence;
            in
            if cfg.enable then cfg.persistPath else ""
          }/etc/ssh/ssh_host_ed25519_key"
        ];
        generateKey = lib.mkDefault false;
      };
    };
}
