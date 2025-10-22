{
  unify.nixos =
    { lib, hostConfig, ... }:
    {
      networking.hostName = lib.mkDefault hostConfig.name;
    };
}
