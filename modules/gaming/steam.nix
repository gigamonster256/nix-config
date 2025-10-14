{
  unify.modules.gaming.nixos = {
    programs.steam.enable = true;
    hardware.steam-hardware.enable = true;
    services.joycond.enable = true;
  };
}
