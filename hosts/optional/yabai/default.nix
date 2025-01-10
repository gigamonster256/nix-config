{
  services = {
    yabai = let
      yabaiConfig = import ./yabai.nix;
    in {
      enable = true;
      inherit (yabaiConfig) config extraConfig;
    };
    skhd = {
      enable = true;
      skhdConfig = import ./skhd.nix;
    };
  };
}
