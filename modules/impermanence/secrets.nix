{
  # if impermanence is enabled, mkBefore the persistent version of the host ssh key
  unify.modules.impermanence.nixos =
    { lib, ... }:
    {
      sops.age.sshKeyPaths = lib.mkBefore [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    };
}
