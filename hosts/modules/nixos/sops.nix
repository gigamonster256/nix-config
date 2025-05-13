{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkDefault
    ;
in
{
  sops.age = {
    sshKeyPaths = mkDefault [
      "${
        let
          cfg = config.impermanence;
        in
        if cfg.enable then cfg.persistPath else ""
      }/etc/ssh/ssh_host_ed25519_key"
    ];
    generateKey = mkDefault false;
  };
}
