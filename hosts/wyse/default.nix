{ self, config, ... }:
{
  # build all hosts in CI
  ci.x86_64-linux.nixos = [ "wyse-91" "wyse-CW" "wyse-DX" "wyse-F4" "wyse-F8" ];

  unify.modules.wyse.nixos =
    { lib, hostConfig, ... }:
    {
      imports = [
        config.unify.modules.facter.nixos
        config.unify.modules.disko.nixos
        config.unify.modules.node_exporter.nixos
      ];

      # less nixos configuration versions to keep around vs default 20
      boot.loader.systemd-boot.configurationLimit = 7;

      # lets try some auto gc
      nix.gc.automatic = true;

      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keys = config.meta.owner.sshKeys;
      facter.reportPath = lib.mkOverride 750 ./${lib.removePrefix "wyse-" hostConfig.name}/facter.json;
      disko = lib.mkOverride 1250 self.diskoConfigurations.wyse.disko; # use default disko configuration for wyse host of a more specific name is not found
      sops.defaultSopsFile = ./${lib.removePrefix "wyse-" hostConfig.name}/secrets.yaml;
      system.stateVersion = lib.mkDefault "26.05";
    };
}
