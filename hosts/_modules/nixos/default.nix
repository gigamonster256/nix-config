{
  flake.modules.nixos.base =
    { lib, config, ... }:
    {

      home-manager.backupFileExtension = lib.mkDefault "backup";
      services.blueman.enable = lib.mkDefault config.hardware.bluetooth.enable;
      # TODO: fix this up
      networking.useNetworkd = true; # https://github.com/nix-community/nixos-facter-modules/issues/83
    };
}
