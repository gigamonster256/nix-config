{ self, config, ... }:
{
  unify.modules.wyse.nixos =
    { lib, hostConfig, ... }:
    {
      imports = [
        config.unify.modules.facter.nixos
        config.unify.modules.disko.nixos
        config.unify.modules.node_exporter.nixos
      ];
      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keys = config.meta.owner.sshKeys;
      facter.reportPath = lib.mkOverride 750 ./${lib.removePrefix "wyse-" hostConfig.name}/facter.json;
      disko = lib.mkOverride 1250 self.diskoConfigurations.wyse.disko; # use default disko configuration for wyse host of a more specific name is not found
      sops.defaultSopsFile = ./${lib.removePrefix "wyse-" hostConfig.name}/secrets.yaml;
      system.stateVersion = lib.mkDefault "26.05";
    };
}
