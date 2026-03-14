{ self, ... }@flake:
{
  # build all hosts in CI
  flake.ci.x86_64-linux.nixos = [
    "wyse-91"
    "wyse-CW"
    "wyse-DX"
    "wyse-F4"
    "wyse-F8"
  ];

  flake.modules.nixos.wyse =
    { lib, config, ... }:
    {
      imports = [
        self.modules.nixos.facter
        self.modules.nixos.disko
        self.modules.nixos.minimal
        self.modules.nixos.node_exporter
      ];

      # less nixos configuration versions to keep around vs default 20
      boot.loader.systemd-boot.configurationLimit = 7;

      # lets try some auto gc
      nix.gc.automatic = true;

      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keys = flake.config.meta.owner.sshKeys;
      facter.reportPath = lib.mkOverride 750 ./${lib.removePrefix "wyse-" config.networking.hostName}/facter.json;
      disko = lib.mkOverride 1250 self.diskoConfigurations.wyse.disko; # use default disko configuration for wyse host of a more specific name is not found
      sops.defaultSopsFile = ./${lib.removePrefix "wyse-" config.networking.hostName}/secrets.yaml;
      system.stateVersion = lib.mkDefault "26.05";
    };
}
