{
  flake.modules.nixos.facter =
    { lib, config, ... }:
    {
      # nixos-facter modules are part of nixpkgs now
      hardware.facter.reportPath = lib.mkDefault ../../hosts/${config.networking.hostName}/facter.json;
    };
}
