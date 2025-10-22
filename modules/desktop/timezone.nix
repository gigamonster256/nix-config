{
  unify.modules.desktop.nixos =
    { lib, ... }:
    {
      # set default time zone for desktop environments
      time.timeZone = lib.mkDefault "America/Chicago";
    };
}
