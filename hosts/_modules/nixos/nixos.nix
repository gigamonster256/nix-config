{
  flake.modules.nixos.base =
    { lib, config, ... }:
    {
      boot.loader.systemd-boot.configurationLimit = lib.mkDefault 20;
      system.autoUpgrade = {
        enable = lib.mkDefault true;
        flake = lib.mkDefault "github:gigamonster256/nix-config";
        # TODO: hmm this seems a little unsafe
        flags = [ "--accept-flake-config" ];
      };
    };
}
