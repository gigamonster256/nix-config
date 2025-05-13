{
  lib,
  config,
  ...
}: {
  sops.age = {
    sshKeyPaths = lib.mkDefault [
      "${
        if config.impermanence.enable
        then config.impermanence.persistPath
        else ""
      }/etc/ssh/ssh_host_ed25519_key"
    ];
    generateKey = lib.mkDefault false;
  };
}
