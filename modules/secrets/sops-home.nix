{ inputs, ... }:
{
  flake.modules.homeManager.base =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.homeModules.sops ];
      sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    };
}
