{
  flake.modules.nixos.desktop =
    { lib, ... }:
    {
      # set default time zone for desktop environments
      time.timeZone = lib.mkDefault "America/Chicago";
    };
}
