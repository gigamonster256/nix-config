{config, ...}: {
  services = {
    yabai = let
      yabaiConfig = import ./yabai.nix;
    in {
      inherit (yabaiConfig) config extraConfig;
    };
    skhd = {
      enable = config.services.yabai.enable;
      skhdConfig = import ./skhd.nix;
    };
  };
}
