{
  flake.modules.darwin.base =
    { config, ... }:
    {
      services = {
        yabai =
          let
            yabaiConfig = import ./_yabai.nix;
          in
          {
            inherit (yabaiConfig) config extraConfig;
          };
        skhd = {
          enable = config.services.yabai.enable;
          skhdConfig = import ./_skhd.nix;
        };
      };
    };
}
