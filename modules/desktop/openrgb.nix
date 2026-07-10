{
  persistence.programs.nixos-home = {
    openrgb = {
      namespace = [
        "services"
        "hardware"
      ];
      directories = [ ".config/OpenRGB" ];
    };
  };
}
